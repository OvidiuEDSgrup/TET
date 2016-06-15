--***
--select * from dbo.fBenef('1',	0,'1901-01-01','2013-5-31','1000002','%','419',	0, 0, 0,0,0,0,'2011-12-31', '%','4426', '', 0)
create function  fBenef(@Sb varchar(9),	--> subunitate
			@IstFactImpl int,@DataJ datetime,@DataS datetime,
			--> filtre
			@Tert varchar(13),@Fact varchar(20),@cCt varchar(13),
			@Ignor4428Avans int, @4428DocFF int, @GenUni int, @DocSch int,@LME int,@FactBil int,@DataJMF datetime, @locm varchar(20),
			@contTvaDeductibil varchar(20), @userASiS varchar(30), @filtrareUser bit)
returns 
table
	/*--@docbenef 
	(subunitate char(9),tert char(13),factura char(20),tip char(2),numar char(20),data datetime,valoare float,tva float,achitat float,valuta char(3),curs float,total_valuta float,achitat_valuta float,
	loc_de_munca char(13),comanda char(40),cont_de_tert char(20),fel int,cont_coresp char(20),explicatii char(50),numar_pozitie int,gestiune char(13),data_facturii datetime,data_scadentei datetime,punct_livrare char(5),	barcod char(30),
	i.loc_de_munca, i.comanda, i.cont_de_tert, '1' fel, '' cont_coresp, 'Sold initial' explicatii, 0 numar_pozitie, '' gestiune, i.data data_facturii, i.data_scadentei, '' punct_livrare, '' barcod, '' contTVA,'' as cod,0 as cantitate,
	contTVA char(13), cod char(20), cantitate float, contract char(20), data_platii datetime)
begin

declare @LFact int
set @LFact=isnull((select c.length from sysobjects o, syscolumns c where o.name='facturi' and o.id=c.id and c.name='factura'), 0)

declare @userASiS varchar(10), @contTvaDeductibil varchar(20)
--, dbo.f_areLMFiltru(@userASiS) int
select	@userASiS=dbo.fIaUtilizator(null)
		,@contTvaDeductibil=rtrim(isnull((select val_alfanumerica from par where tip_parametru='GE' and parametru='CDTVA'),'4426'))
	insert @docbenef
*/

as return
(
select i.subunitate,i.tert,i.factura,'SI' tip ,i.factura numar,i.data,i.valoare,i.tva_11+i.tva_22 tva,i.achitat ,i.valuta, i.curs, i.valoare_valuta total_valuta, i.achitat_valuta,
		i.loc_de_munca, i.comanda, i.cont_de_tert, '1' fel, '' cont_coresp, 'Sold initial' explicatii, 0 numar_pozitie, '' gestiune, i.data data_facturii, i.data_scadentei,
		isnull((select top 1 left(d.gestiune_primitoare,5) from doc d where d.subunitate=i.subunitate and d.tip in ('AP','AS') and d.factura=i.factura and d.cod_tert=i.tert), '') punct_livrare, 
		'' barcod, '' contTVA,'' as cod,0 as cantitate,
		'' contract, i.data as data_platii
from istfact i
left outer join terti t on i.subunitate=t.subunitate and i.tert=t.tert 
left join lmfiltrare pr on pr.cod=i.loc_de_munca and pr.utilizator=@userASiS
where @IstFactImpl=1 and i.subunitate=@Sb and i.tip='B' and i.data_an=@DataJ
	and (@tert='%' or i.tert like rtrim(@Tert)) and (@fact='%' or i.factura like rtrim(@Fact)) and (@cCt='' or i.Cont_de_tert like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS)
	and (@locm='%' or i.Loc_de_munca like @locm)
union all 
select fi.subunitate,fi.tert,fi.factura,'SI',fi.factura,fi.data,fi.valoare,fi.tva_11+fi.tva_22,fi.achitat,fi.valuta,fi.curs,fi.valoare_valuta,
		fi.achitat_valuta,fi.loc_de_munca,fi.comanda,fi.cont_de_tert,'1','','Sold initial',0,'',fi.data,fi.data_scadentei,
		isnull((select top 1 left(d.gestiune_primitoare,5) from doc d where d.subunitate=fi.subunitate and d.tip in ('AP','AS') and d.factura=fi.factura and d.cod_tert=fi.tert), 
			isnull((select top 1 i.serie_doc from incfact i where i.subunitate=fi.subunitate and i.numar_factura=fi.factura and i.tert=fi.tert), '')),
		'','' contTVA,'' as cod,0 as cantitate, '' contract, fi.data
from factimpl fi 
left join lmfiltrare pr on pr.cod=fi.loc_de_munca and pr.utilizator=@userASiS
left outer join terti t on fi.subunitate=t.subunitate and fi.tert=t.tert 
where @IstFactImpl=2 and fi.subunitate=@Sb and fi.tip=0x46 
	  and (@tert='%' or fi.tert like rtrim(@Tert)) and (@fact='%' or fi.factura like rtrim(@Fact)) and (@cCt='' or fi.Cont_de_tert like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS)
	and (@locm='%' or fi.Loc_de_munca like @locm)
union all 
select p.subunitate,p.tert,p.factura,p.tip,numar,p.data,round(convert(decimal(18,5),cantitate*p.pret_vanzare),2),
		(case when not (p.tip in ('AP','AS') and @GenUni=0 and (@DocSch=0 or p.tip='AS') and p.procent_vama in (1, 2)) then tva_deductibil else 0 end),
		0,p.valuta,p.curs,(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then round(
			convert(decimal(18,5),cantitate*(pret_valuta+(case when @LME=1 and p.tip='AP' then p.suprataxe_vama/1000 else 0 end))*(1-discount/100))+
			(case when not (p.tip in ('AP','AS') and @GenUni=0 and (@DocSch=0 or p.tip='AS') and p.procent_vama in (1, 2)) and p.curs>0 
					then TVA_deductibil/p.curs else 0 end),2) else 0 end),
		0,p.loc_de_munca,p.comanda,cont_factura,'2',cont_venituri,left(isnull(mfix.denumire, isnull(n.denumire,'Iesiri')),50),numar_pozitie,
		p.gestiune,data_facturii,p.data_scadentei,substring(p.numar_dvi, 14, 5),p.barcod,
		(case when p.tip in ('AP','AS') then p.grupa  else p.cont_venituri end) as contTVA,p.cod as cod,p.Cantitate as cantitate, 
		(case when p.Tip in ('AP','AS') then p.Contract else '' end), p.data
from pozdoc p 
left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
left outer join nomencl n on n.cod=p.cod
left outer join mfix on isnull(n.tip, '')='F' and mfix.subunitate=p.subunitate and mfix.numar_de_inventar=p.cod_intrare
where p.subunitate=@Sb and p.tip in ('AP','AS') and (@FactBil=1 or p.cont_factura<>'' or left(p.cont_de_stoc,1)<>'8') and 
	p.data between @DataJ and @DataS 
		and (@tert='%' or p.tert like rtrim(@Tert)) and (@fact='%' or p.factura like rtrim(@Fact)) and (@cCt='' or p.cont_factura like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS	)
	and (@locm='%' or p.Loc_de_munca like @locm)
union all 
select p.subunitate,p.tert,p.factura,p.plata_incasare,p.numar,p.data,0,0,
		(case when p.plata_incasare in ('PS','IS') then -1 else 1 end)*(p.suma-suma_dif)
			-(case when p.plata_incasare='IB' and @Ignor4428Avans=0 and left(p.Cont_corespondent,3) in ('419','451') then p.TVA22 else 0 end),
		p.valuta,p.curs,0,
		(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when plata_incasare in ('PS','IS') then -1 else 1 end)*
			achit_fact,p.loc_de_munca,p.comanda,p.cont_corespondent,'3',p.cont,explicatii,p.numar_pozitie,left(p.comanda,9),p.data,p.data,
		'','','' contTVA, '' as cod,0 as cantitate, '' contract, isnull(e.Data_document,p.Data) as data_platii
from pozplin p 
left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
left join extpozplin e on p.Subunitate=e.Subunitate and p.Cont=e.Cont and p.Data=e.Data
	and p.Numar_pozitie=e.Numar_pozitie and p.Numar=e.Numar
where p.subunitate=@Sb and p.plata_incasare in ('IB','IR','PS') and p.data between @DataJ and @DataS 
	and (@tert='%' or p.tert like rtrim(@Tert)) and (@fact='%' or p.factura like rtrim(@Fact)) and (@cCt='' or p.Cont_corespondent like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS)
	and (@locm='%' or p.Loc_de_munca like @locm)
--
union all 
select	p.subunitate,p.tert,factura_stinga,p.tip,p.numar_document,p.data,(case when p.tip='CB' then 0 else suma end),
		(case when p.tip='CB' or p.stare in (1, 2) then 0 else tva22 end),
		(case when p.tip='CB' then -suma+(case when @Ignor4428Avans=0 and left(p.Cont_deb,3) in ('419','451') then p.TVA22 else 0 end) else 0 end),
		p.valuta,p.curs,
		(case when p.valuta='' or isnull(t.tert_extern,0)=0 or p.tip='CB' then 0 else suma_valuta+
			(case	when p.tip in ('IF','FB') and p.stare=1 then 0 when p.tip='FB' then dif_TVA 
					when p.tip='IF' then convert(float,tert_beneficiar) else 0 end) end),
		(case when p.valuta='' or isnull(t.tert_extern,0)=0 then 0 when p.tip='CB' then -suma_valuta else 0 end),loc_munca,p.comanda,cont_deb,
		'4',cont_cred,explicatii,numar_pozitie,'',data_fact,data_scad,'','',
		(case when p.tip='IF' then @contTvaDeductibil else p.tert_beneficiar end)
		contTVA, '' as cod,0 as cantitate,'' contract,
		p.data
from pozadoc p 
left join lmfiltrare pr on pr.cod=p.loc_munca and pr.utilizator=@userASiS
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
where p.subunitate=@Sb and p.tip in ('CB','FB','IF') and p.data between @DataJ and @DataS
	and (@tert='%' or p.tert like rtrim(@Tert)) and (@fact='%' or p.Factura_stinga like rtrim(@Fact)) and (@cCt='' or p.Cont_deb like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS)
	and (@locm='%' or p.Loc_munca like @locm)
union all 
select p.subunitate,p.tert,factura_dreapta,(case when p.tip='IF' then 'IX' when p.tip='CB' then 'BX' else p.tip end),numar_document,p.data,
		0,0,suma+(case when p.tip in ('CB','IF') then (case when left(cont_dif,1)='6' then suma_dif else -suma_dif end) else 0 end)+
			(case when p.tip='IF' and p.stare not in (1, 2) then TVA22-dif_TVA else 0 end),p.valuta,p.curs,0,
		(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then achit_fact+
			(case when p.tip='IF' and p.stare<>1 and isnumeric(p.tert_beneficiar)=1 and p.TVA22<>0 
					then convert(float,tert_beneficiar)*(1.00-p.dif_TVA/p.TVA22) else 0 end) else 0 end),loc_munca,p.comanda,cont_cred,'4',
					cont_deb,explicatii,numar_pozitie,'',data_fact,data_scad,'','','' contTVA, '' as cod,0 as cantitate, '' contract, p.data
from pozadoc p 
left join lmfiltrare pr on pr.cod=p.loc_munca and pr.utilizator=@userASiS
left outer join terti t on p.subunitate=t.subunitate and p.tert=t.tert 
where p.subunitate=@Sb and p.tip in ('CB','CO','IF') and p.data between @DataJ and @DataS
	and (@tert='%' or p.tert like rtrim(@Tert)) and (@fact='%' or p.Factura_dreapta like rtrim(@Fact)) and (@cCt='' or p.Cont_cred like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS)
	and (@locm='%' or (p.Loc_munca) like @locm)
union all 
select p.subunitate,tert_beneficiar,factura_dreapta,p.tip,numar_document,p.data,0,0,suma,p.valuta,p.curs,0,
		(case when p.valuta<>'' and isnull(t.tert_extern,0)=1 then achit_fact else 0 end),loc_munca,p.comanda,cont_cred,'4',cont_deb,explicatii,
		numar_pozitie,'',data_fact,data_scad,'','','' contTVA, '' as cod,0 as cantitate,'' contract, p.data
from pozadoc p 
left join lmfiltrare pr on pr.cod=p.loc_munca and pr.utilizator=@userASiS
left outer join terti t on p.subunitate=t.subunitate and p.tert_beneficiar=t.tert 
where p.subunitate=@Sb and p.tip='C3' and p.data between @DataJ and @DataS
	and (@tert='%' or p.Tert_beneficiar like rtrim(@Tert)) and (@fact='%' or p.Factura_dreapta like rtrim(@Fact)) and (@cCt='' or p.Cont_cred like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS)
	and (@locm='%' or (p.Loc_munca) like @locm)
union all 
select m.subunitate,m.tert,m.factura,'M'+left(tip_miscare,1),numar_document,data_miscarii,pret,tva,0,'',0,0,0,
	isnull((select max(loc_de_munca) from fisaMF where subunitate=@Sb and numar_de_inventar=m.numar_de_inventar and felul_operatiei='5'),''),
	isnull((select max(comanda) from fisaMF where subunitate=@Sb and numar_de_inventar=m.numar_de_inventar and felul_operatiei='5'),''),
	loc_de_munca_primitor,'2',gestiune_primitoare,'miscare mijloc fix: '+left(tip_miscare,1),0,'',data_miscarii,data_miscarii,'','','' contTVA,
	m.Numar_de_inventar as cod,0 as cantitate, '' contract, m.Data_miscarii
from misMF m
left join lmfiltrare pr on pr.cod=m.loc_de_munca_primitor and pr.utilizator=@userASiS
where procent_inchiriere not in (1,6,9) and m.subunitate=@Sb and tip_miscare='EVI' and data_miscarii between @DataJMF and @DataS
	and (@tert='%' or m.tert like rtrim(@Tert)) and (@fact='%' or m.Factura like rtrim(@Fact)) and (@cCt='' or m.Loc_de_munca_primitor like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS)
	and (@locm='%' or (m.Loc_de_munca_primitor) like @locm)
union all							
select p.subunitate,p.tert,(case when p.cod_intrare='' then 'AVANS' 
			else p.cod_intrare end)	--< aici era left(p.cod_intrare,@LFact) in loc de p.cod_intrare; modificat cu ocazia optimizarii
		,'AX',numar,p.data,0,0,	
		round(convert(decimal(18,5),cantitate*p.pret_vanzare),2)+
		(case when @Ignor4428Avans=0 and left(p.Cont_de_stoc,3) in ('419','451') or @4428DocFF=0 and left(p.Cont_de_stoc,3) in ('418','461') then 0 else 1 end)
			*(case when p.tip in ('AP','AS') and @GenUni=0 and (@DocSch=0 or p.tip='AS') and p.procent_vama in (1, 2) then 0 else 1 end)*tva_deductibil,
		p.valuta,p.curs,0,(case when p.valuta<>'' and p.curs>0 then round(convert(decimal(18,5),cantitate*pret_valuta*(1-p.discount/100)),2)+
				round(convert(decimal(18,5),(case when @Ignor4428Avans=0 and left(p.Cont_de_stoc,3) in ('419','451') or @4428DocFF=0 and left(p.Cont_de_stoc,3) in ('418','461') then 0 else 1 end)
					*(case when p.tip in ('AP','AS') and @GenUni=0 and (@DocSch=0 or p.tip='AS') and p.procent_vama in (1, 2) then 0 else 1 end)*tva_deductibil/p.curs),2) else 0 end),	
		p.loc_de_munca,p.comanda,cont_de_stoc,'4',cont_corespondent,left(isnull(n.denumire,''),50),numar_pozitie,'',p.data_facturii,
		p.data_scadentei,substring(p.numar_dvi, 14, 5),p.barcod,'' contTva, p.cod as cod,p.cantitate as cantitate, 
		(case when p.Tip in ('AP','AS') then p.Contract else '' end), p.Data
from pozdoc p 
left join lmfiltrare pr on pr.cod=p.loc_de_munca and pr.utilizator=@userASiS
inner join conturi c on c.subunitate=p.subunitate and c.cont=p.cont_de_stoc and c.sold_credit=2
left outer join nomencl n on n.cod=p.cod
where p.subunitate=@Sb and p.tip in ('AP','AS') and p.data between @DataJ and @DataS
	and (@tert='%' or p.tert like rtrim(@Tert)) and (@fact='%' or (case when p.cod_intrare='' then 'AVANS' else left(p.cod_intrare,20) end) like rtrim(@Fact))
		and (@cCt='' or p.Cont_de_stoc like rtrim(@cCt)+'%')
	and (@filtrareUser=0 or pr.utilizator=@userASiS)
	and (@locm='%' or (p.Loc_de_munca) like @locm)	--*/--*/--*/--*/

)