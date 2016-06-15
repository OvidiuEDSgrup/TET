--***
create procedure wIaPozdocMF @sesiune varchar(50), @parXML xml
as 
set transaction isolation level READ UNCOMMITTED
declare @sub varchar(9), @bugetari int, @lunainch int, @anulinch int, @datainch datetime, 
	@userASiS varchar(10), @iDoc int, @tip varchar(2), @subtip varchar(2), 
	@lista_lm int, @lista_gest int, @datal datetime, @cautare varchar(500)
	
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @sub=dbo.iauParA('GE','SUBPRO')
set @bugetari=dbo.iauParL('GE','BUGETARI')
set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' 
	and parametru='LUNABLOC'), isnull((select max(val_numerica) from par where tip_parametru='GE' 
	and parametru='LUNAINC'), 1))
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' 
	and parametru='ANULBLOC'), isnull((select max(val_numerica) from par where tip_parametru='GE' 
	and parametru='ANULINC'), 1901))
set @datainch=dbo.Eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

select @lista_lm=dbo.f_arelmfiltru(@userASiS), @lista_gest=0
select @lista_gest=1
	from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE'

select @tip=xA.row.value('@tip', 'varchar(2)'), @datal=xA.row.value('@datal', 'datetime'), 
	@cautare=isnull(xA.row.value('@_cautare', 'varchar(500)'),'')
	from @parXML.nodes('row') as xA(row)

select rtrim(a.subunitate) as sub, rtrim(a.Numar_de_inventar) as nrinv, 
	rtrim(x.Denumire) as denmf, @tip as tip, rtrim(right(a.Tip_miscare,2)) as subtip, 
	rtrim(numar_document) as numar, convert(char(10),a.Data_miscarii,101) as data, 
	rtrim(isnull(p.gestiune,isnull(f.gestiune,f.gestiune))) as gest, 
	rtrim(ISNULL(p.Loc_de_munca,ISNULL(f.Loc_de_munca,f.Loc_de_munca))) as lm, 
	rtrim(left(isnull(p.comanda,isnull(f.comanda,f.comanda)),20)) as com, /*rtrim(substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20))*/ 
	isnull(substring(substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20),1,2),'  ')+'.'
		+isnull(substring(substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20),3,2),'  ')+'.'
		+isnull(substring(substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20),5,2),'  ')+'.'
		+isnull(substring(substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20),7,2),'  ')+'.'
		+isnull(substring(substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20),9,2),'  ')+'.'
		+isnull(substring(substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20),11,2),'  ')+'.'
		+isnull(substring(substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20),13,2),'  ') as indbug, 
	/*rtrim(substring(a.subunitate_primitoare,21,20))*/ 
	isnull(substring(substring(a.subunitate_primitoare,21,20),1,2),'  ')+'.'
		+isnull(substring(substring(a.subunitate_primitoare,21,20),3,2),'  ')+'.'
		+isnull(substring(substring(a.subunitate_primitoare,21,20),5,2),'  ')+'.'
		+isnull(substring(substring(a.subunitate_primitoare,21,20),7,2),'  ')+'.'
		+isnull(substring(substring(a.subunitate_primitoare,21,20),9,2),'  ')+'.'
		+isnull(substring(substring(a.subunitate_primitoare,21,20),11,2),'  ')+'.'
		+isnull(substring(substring(a.subunitate_primitoare,21,20),13,2),'  ') as indbugprim, 
	rtrim(x.serie) as seriemf,rtrim(x.tip_amortizare) as tipam,rtrim(x.cod_de_clasificare) as codcl, 
	f.categoria as categmf, convert(char(10),x.Data_punerii_in_functiune,101) as datapf, 
	rtrim(a.tert) as tert, rtrim(a.factura) as fact, 
	convert(char(10),p.Data_facturii,101) as datafact, 
	convert(char(10),a.Data_sfarsit_conservare,101) as datascad, 
	rtrim(p.valuta) as valuta, convert(decimal(10,4),p.Curs) as curs, 
	convert(decimal(14,6),(case when p.valuta='' then a.pret else p.Pret_valuta end)) as pretvaluta, 
	convert(decimal(12,2),a.diferenta_de_valoare) as difvalinv, 
	convert(decimal(12,2),(case when a.tip_miscare='MRE' and a.factura<>'' then 
	rtrim(a.factura) else '0' end)) as ajust, 
	convert(decimal(12,2),a.pret) as pret, 
	convert(decimal(5,2),p.Cota_TVA) as cotatva, 
	convert(decimal(12,2),a.TVA) as sumatva, 
	convert(decimal(12,2),a.TVA+a.pret) as valfact, 
	convert(int,(case when a.tip_miscare='IAF' and a.procent_inchiriere=6 then 
		(case when exists (select 1 from pozdoc pt
				where pt.subunitate=a.subunitate and pt.tip='RM' and pt.numar=a.Numar_document and
					pt.Data=a.Data_miscarii and pt.cod='TVANCN' and pt.Cod_intrare=a.Numar_de_inventar and pt.cont_de_stoc=p.cont_de_stoc) then 5
			when exists (select 1 from pozdoc pt
				where pt.subunitate=a.subunitate and pt.tip='RM' and pt.numar=a.Numar_document and
					pt.Data=a.Data_miscarii and pt.cod='TVANCN' and pt.Cod_intrare=a.Numar_de_inventar) then 4 else p.procent_vama end) else p.procent_vama end)) as tiptva, 
	convert(decimal(12,2),f.valoare_de_inventar) as valinv, 
	convert(decimal(12,2),f.Valoare_amortizata) as valam, 
	convert(decimal(12,2),f.Valoare_amortizata_cont_8045) as valamcls8, 
	convert(decimal(12,2),f.Valoare_amortizata_cont_6871) as valamneded, 
	convert(decimal(12,2),fa.Valoare_amortizata) as valamist, 
	convert(decimal(12,2),f.Cantitate) as rezreev, 
	convert(decimal(12,2),f.Amortizare_lunara) as amlun, 
	convert(int,f.Obiect_de_inventar) as tipmf, 
	rtrim(xd.Serie) /*(case when xd.serie='O' then 1 else 0 end)*/ as subtipmf, f.durata as durata, 
	f.Numar_de_luni_pana_la_am_int as nrluni, rtrim(f.Cont_mijloc_fix) as contmf, 
	rtrim(a.cont_corespondent) as contcor, rtrim(left(a.Subunitate_primitoare,20)) as contamcomprim, 
	rtrim(isnull(nullif(p.detalii.value('(/row/@contcham)[1]','varchar(20)'),''),x.detalii.value('(/row/@contcham)[1]','varchar(20)'))) as contcham,
	rtrim(a.Gestiune_primitoare) as contgestprim, 
	(case when a.tip_miscare='MRE' and rtrim(a.Loc_de_munca_primitor)='' then space(2) else rtrim(a.Loc_de_munca_primitor) end) as contlmprim, --	pus space(2) daca sa functioneze initializarea Combo Box-ului.
	rtrim((case a.tip_miscare when 'EVI' then p.grupa else p.Cont_venituri end)) as conttva, 
	rtrim((case a.tip_miscare when 'MTP' then p.detalii.value('(/row/@contpatrimiesire)[1]','varchar(20)') end)) as contpatrimiesire,
	rtrim((case a.tip_miscare when 'MTP' then p.detalii.value('(/row/@contpatrimintrare)[1]','varchar(20)') end)) as contpatrimintrare,
	rtrim(p.cod) as cod, convert(int,a.Procent_inchiriere) as procinch, 
	isnull(p.numar_pozitie,0) as nrpozitie, 
	(case when rtrim(xd.Tip_amortizare)='' then space(1) else rtrim(xd.Tip_amortizare) end) as patrim, rtrim(xd.denumire) as denalternmf, 
	rtrim(xd2.denumire) as prodmf, rtrim(xd2.serie) as modelmf, 
	rtrim(xd2.cod_de_clasificare) as nrinmatrmf, rtrim(xd3.serie) as durfunct, 
	rtrim(xd3.cod_de_clasificare) as staremf, 
	convert(char(10),xd3.Data_punerii_in_functiune,101) as datafabr, 
	p.Tip as tipdocCG, isnull(rtrim(left(gest.denumire_gestiune, 30)), '') as dengest, 
	isnull(rtrim(left(gestP.denumire_gestiune, 30)), '') as dengestprim, 
	isnull(rtrim(lm.denumire), '') as denlm, isnull(rtrim(lmp.denumire), '') as denlmprim, 
	isnull(rtrim(com.descriere), '') as dencom, isnull(rtrim(comp.descriere), '') as dencomprim, 
	isnull(rtrim(t.denumire), '') as dentert,  --isnull(rtrim(n.denumire), '') as dencod,  
	isnull(rtrim(i.denumire), '') as denindbug, isnull(rtrim(ip.denumire), '') as denindbugprim, 
	isnull(rtrim(cc.Denumire), '') as dencodcl, 
	(case when 90=0 and ISNULL(p.stare,0)=2 or a.Data_miscarii<=@datainch 
		or left(a.tip_miscare,1) in ('E','I','M') 
		and a.procent_inchiriere in (1,2) then '#808080' else '#000000' end) as culoare,
	(case when 90=0 and ISNULL(p.stare,0)=2 or a.Data_miscarii<=@datainch or left(a.tip_miscare,1) in 
		('E','I','M') and a.procent_inchiriere in (1,2) or a.Tip_miscare='ESU' and a.Tert='' then 1 else 0 end) 
		as _nemodificabil
FROM mismf a 
	LEFT outer join mfix x on x.subunitate=@sub --left(x.subunitate,4)<>'DENS' 
		and x.Numar_de_inventar=a.Numar_de_inventar 
	LEFT outer join mfix xd on (left(a.tip_miscare,1)='I' or tip_miscare='MTP') and xd.subunitate='DENS' 
		and xd.Numar_de_inventar=a.Numar_de_inventar 
	LEFT outer join mfix xd2 on left(a.tip_miscare,1)='I' and xd2.subunitate='DENS2' 
		and xd2.Numar_de_inventar=a.Numar_de_inventar 
	LEFT outer join mfix xd3 on left(a.tip_miscare,1)='I' and xd3.subunitate='DENS3' 
		and xd3.Numar_de_inventar=a.Numar_de_inventar 
	LEFT outer join fisamf f on f.subunitate=a.subunitate and f.Numar_de_inventar=a.Numar_de_inventar 
		and f.Data_lunii_operatiei=(case when left(a.tip_miscare,1)='T' then dbo.bom(Data_lunii_de_miscare)-1 
			else Data_lunii_de_miscare end)
		and f.Felul_operatiei=(case @tip when 'MI' then '3' when 'MM' then '4' when 'ME' then '5' 
			when 'MT' then '1' when 'MC' then '7' when 'MS' then '8' when 'MB' then '9' else '1' end) 
	/* Am activat acest join pentru cazul transferurilor din luna intrarii. In aceste cazuri, nu exista pozitie cu fel 1 pe luna anterioara */
	LEFT outer join fisamf f6 on left(a.tip_miscare,1)='T' and f6.subunitate=a.subunitate 
	and f6.Numar_de_inventar=a.Numar_de_inventar and f6.Data_lunii_operatiei=Data_lunii_de_miscare 
	and f6.Felul_operatiei='6'
	LEFT outer join fisamf fa on a.tip_miscare='ISU' and fa.subunitate=a.subunitate 
		and fa.Numar_de_inventar=a.Numar_de_inventar and fa.Data_lunii_operatiei=Data_lunii_de_miscare 
		and fa.Felul_operatiei='A' 
	LEFT outer join pozdoc p on (left(a.tip_miscare,1) in ('E','I','M') or left(a.tip_miscare,1)='T' and p.cantitate<0) and a.procent_inchiriere=6 
		and p.subunitate=a.subunitate and p.tip=(case left(a.tip_miscare,1) 
			when 'I' then (case right(a.tip_miscare,2) when 'AF' then 'RM' else 'AI' end)
			when 'M' then (case right(a.tip_miscare,2) when 'EP' then 'AE' when 'FF' then 'RM' else 'AI' end)
			when 'E' then (case right(a.tip_miscare,2) when 'SU' then 'AE' when 'VI' then 'AP' else 'AE' end)
			when 'T' then 'AI'
			else '' end) and p.numar=a.Numar_document and p.Data=a.Data_miscarii and p.Cod_intrare=a.Numar_de_inventar --and p.subtip = 'MF'
	left outer join terti t on a.tip_miscare in ('EVI','MFF','IAF') and t.subunitate = a.subunitate 
		and t.tert = a.tert  
	left outer join gestiuni gest on gest.cod_gestiune = isnull(p.gestiune,isnull(f.gestiune,isnull(f6.gestiune,f.gestiune)))
	left outer join gestiuni gestP on left(a.tip_miscare,1)='T' and gestP.cod_gestiune=a.gestiune_primitoare 
	left outer join lm on lm.cod = ISNULL(p.Loc_de_munca,ISNULL(f.Loc_de_munca,isnull(f6.Loc_de_munca,f.Loc_de_munca)))
	left outer join lm lmp on left(a.tip_miscare,1)='T' and lmp.cod = a.Loc_de_munca_primitor 
	left outer join comenzi com on com.subunitate = a.subunitate 
		and com.comanda = isnull(p.comanda,isnull(f.comanda,f.comanda))
	left outer join comenzi comp on left(a.tip_miscare,1)='T' and comp.subunitate = a.subunitate 
		and comp.comanda = left(a.Subunitate_primitoare,20) 
	left outer join indbug i on @bugetari=1 and i.Indbug = substring(isnull(p.comanda,isnull(f.comanda,f.comanda)),21,20)
	left outer join indbug ip on @bugetari=1 and left(a.tip_miscare,1)='T' 
		and ip.Indbug = substring(a.subunitate_primitoare,21,20)
	left outer join Codclasif cc on left(a.tip_miscare,1)='I' and cc.Cod_de_clasificare = x.Cod_de_clasificare
	left outer join LMFiltrare lu on lu.utilizator=@userASiS 
		and lu.cod=ISNULL(p.Loc_de_munca,ISNULL(f.Loc_de_munca,f.Loc_de_munca))
		/*left outer join proprietati prop on prop.Cod_proprietate='GESTIUNE' and prop.tip='UTILIZATOR' 
		and prop.cod=@userASiS and prop.valoare=isnull(p.gestiune,isnull(f.gestiune,f.gestiune))*/
WHERE a.subunitate in (@sub,'DENS') --(@tip='SL' and a.marca=xA.row.value('@marca','varchar(6)') or @tip='AV' and ISNULL(p.Loc_de_munca,ISNULL(f.Loc_de_munca,f.Loc_de_munca))=@grupdoc) 
	and (@lista_lm=0 or lu.cod is not null) --and (@lista_gest=0 or prop.valoare is not null)
	and left(a.Tip_miscare,1)=RIGHT(@tip,1) and Data_lunii_de_miscare=@datal
	and (a.Numar_de_inventar like @cautare+'%' or x.denumire like '%'+@cautare+'%' or a.Numar_document like @cautare+'%' 
		or isnull(p.gestiune,isnull(f.gestiune,f.gestiune)) like @cautare+'%' or gest.denumire_gestiune like '%'+@cautare+'%'
		or ISNULL(p.Loc_de_munca,ISNULL(f.Loc_de_munca,f.Loc_de_munca)) like @cautare+'%' or lm.denumire like '%'+@cautare+'%') 
	and (Procent_inchiriere in (1,3,6,9) /*and Procent_inchiriere not in (7,8)*/
		or a.Tip_miscare in ('BIN','CON','RCI','SCO','TSE')) --and (a.Tip_miscare<>'ESU' or a.Tert='AE') 
	and isnull(p.cod,'')<>'TVANCN' --and a.data_miscarii between @dataj and @datas
order by data_miscarii, numar_document, a.Numar_de_inventar
for xml raw
