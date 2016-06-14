--***
if exists (select * from sysobjects where name ='wIaDocSP')
drop procedure wIaDocSP
go
--***
create procedure wIaDocSP @sesiune varchar(50), @parXML xml
as

begin try
set transaction isolation level read uncommitted
declare @Sub char(9), @userASiS varchar(10), @facturiDefinitive int, @mesaj varchar(2000), 
	@tip varchar(2), @numar varchar(50), @data datetime, @f_data_jos datetime, @f_data_sus datetime, @f_numar varchar(50), 
	@f_gestiune varchar(50), @f_denumire_gestiune varchar(50), @f_gestiune_primitoare varchar(50), @f_denumire_gestiune_primitoare varchar(50), 
	@f_tert varchar(50), @f_denumire_tert varchar(50), @f_dencontvenituri varchar(50),
	@f_comanda varchar(50), @f_denumire_comanda varchar(50), @f_lm varchar(50), @f_denumire_lm varchar(50), 
	@f_valoare_minima float, @f_valoare_maxima float, @f_factura varchar(50), @f_data_facturii_jos datetime, @f_data_facturii_sus datetime, 
	@f_contractcor varchar(50), @f_stare varchar(50), @tip_doc varchar(2),
	@lista_gestiuni bit, @lista_clienti bit, @lista_lm bit,@CTCLAVRT bit,@ContAvizNefacturat varchar(20)--/*SP
	,@f_contract varchar(20) --SP*/

exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec luare_date_par 'GE','FACTDEF',@facturiDefinitive output,0,'' 

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

select	@tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@numar = ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(8)'),''),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@f_data_jos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'),'01/01/1901'),
		@f_data_sus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'),'12/31/2999'),
		@f_numar = ISNULL(@parXML.value('(/row/@f_numar)[1]', 'varchar(8)'),''),
		@f_gestiune = ISNULL(@parXML.value('(/row/@f_gestiune)[1]', 'varchar(9)'),''),
		@f_denumire_gestiune = ISNULL(@parXML.value('(/row/@f_dengestiune)[1]', 'varchar(30)'),''),
		@f_gestiune_primitoare = ISNULL(@parXML.value('(/row/@f_gestprim)[1]', 'varchar(9)'),''),
		@f_denumire_gestiune_primitoare = ISNULL(@parXML.value('(/row/@f_dengestprim)[1]', 'varchar(30)'),''),
		@f_tert = ISNULL(@parXML.value('(/row/@f_tert)[1]', 'varchar(13)'),''),
		@f_denumire_tert = ISNULL(@parXML.value('(/row/@f_dentert)[1]', 'varchar(80)'),''),
		@f_dencontvenituri = ISNULL(@parXML.value('(/row/@f_dencontvenituri)[1]', 'varchar(80)'),''),
		@f_comanda = ISNULL(@parXML.value('(/row/@f_comanda)[1]', 'varchar(20)'),''),
		@f_denumire_comanda = ISNULL(@parXML.value('(/row/@f_dencomanda)[1]', 'varchar(80)'),''),
		@f_lm = ISNULL(@parXML.value('(/row/@f_lm)[1]', 'varchar(9)'),''),
		@f_denumire_lm = ISNULL(@parXML.value('(/row/@f_denlm)[1]', 'varchar(30)'),''),
		@f_valoare_minima = ISNULL(@parXML.value('(/row/@f_valoarejos)[1]', 'float'),-99999999999),
		@f_valoare_maxima = ISNULL(@parXML.value('(/row/@f_valoaresus)[1]', 'float'),99999999999),
		@f_factura = ISNULL(@parXML.value('(/row/@f_factura)[1]', 'varchar(20)'),''),
		@f_data_facturii_jos = @parXML.value('(/row/@f_datafacturiijos)[1]', 'datetime'),
		@f_data_facturii_sus = @parXML.value('(/row/@f_datafacturiisus)[1]', 'datetime'),
		@f_contractcor = ISNULL(@parXML.value('(/row/@f_contractcor)[1]', 'varchar(20)'),''),
		@f_stare = ISNULL(@parXML.value('(/row/@f_stare)[1]', 'varchar(20)'),'')--/*SP
		,@f_contract = ISNULL(@parXML.value('(/row/@f_contract)[1]', 'varchar(20)'),'') --SP*/

-- variabila folosita pt. filtrarea tipului de document in tabela doc/pozdoc, pentru ca sa nu facem multe case-uri
set @tip_doc=case when @tip='RC' then 'RM' else @tip end

select 'G' as tip_gestiune, cod_gestiune, left(Denumire_gestiune,30) as Denumire_gestiune 
into #gest 
from gestiuni where Subunitate=@Sub 
union all 
select 'F', marca, nume from personal
CREATE UNIQUE CLUSTERED INDEX Idx1 ON #gest (tip_gestiune, cod_gestiune)


declare @GestiuniUser table(valoare varchar(9))
declare @ClientiUser table(valoare varchar(9))
insert @GestiuniUser(valoare)
select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE' and Valoare<>''
insert @ClientiUser(valoare)
select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CLIENT' and Valoare<>''

select @lista_gestiuni=0, @lista_clienti=0, @lista_lm=0
if exists (select * from @GestiuniUser)
	set @lista_gestiuni=1
if exists (select * from @ClientiUser)
	set @lista_clienti=1
if exists (select * from LMFiltrare l where l.utilizator=@userASiS)
	set @lista_lm=1


/*Pentru filtrare pe folosinta sau gestiune*/
declare @tipGestFiltrare char(1) /*Predator*/
	,@tipGestFiltrareP char(1) /*Primitor*/

set @tipGestFiltrare=(case when @tip_doc in ('PF','CI','AF') then 'F' else 'G' end)
set @tipGestFiltrareP=(case when @tip_doc='TE' then 'G' else 'F' end)

select top 100 d.subunitate,d.tip,d.numar,d.data--, d.tva_11, d.tva_22  
into #d100
from doc d
	left outer join terti t on t.subunitate = d.subunitate and t.tert = d.cod_tert 
	left outer join #gest gPred on gPred.cod_gestiune = d.cod_gestiune and gPred.tip_gestiune=@tipGestFiltrare
	left outer join #gest gPrim on gPrim.cod_gestiune = d.gestiune_primitoare and gPrim.tip_gestiune=@tipGestFiltrareP
	left outer join lm on lm.cod = d.loc_munca
	left outer join comenzi com on com.subunitate = @sub and com.comanda = left(d.comanda,20)  
	left outer join indbug indb on indb.Indbug = substring(d.comanda,21,20)
	left outer join @GestiuniUser gu on gu.valoare=d.Cod_gestiune
	left outer join @GestiuniUser gpu on @tip_doc='TE' and gpu.valoare=d.Gestiune_primitoare
	left outer join conturi cf on @tip_doc not in ('PP', 'CM', 'PF', 'CI', 'AF') and cf.Subunitate=@sub and cf.Cont=d.Cont_factura
	left outer join infotert tpctliv on @tip_doc in ('AP','AS','AC') and tpctliv.Subunitate=@sub and tpctliv.Tert=d.cod_tert and tpctliv.identificator=d.gestiune_primitoare
	left outer join categpret cpret on cpret.Categorie=d.Discount_suma
	left outer join anexadoc ad on ad.Subunitate=@sub and ad.Tip=@tip_doc and ad.Numar=d.Numar and ad.Data=d.Data and ad.Tip_anexa=''
	left outer join con on d.Contractul=con.Contract and d.Data=con.Data and con.Tip='BK' and con.Subunitate=@Sub
	left outer join incfact inf on @facturiDefinitive=1 and @tip_doc='AP' and inf.subunitate=@sub and inf.Numar_factura=d.factura and inf.Numar_pozitie=1
	left outer join valuta v on v.Valuta=d.Valuta
where d.subunitate=@Sub --and d.Jurnal<>'MFX' 
	and d.tip = @tip_doc 
	and (@tip='RC' and d.jurnal='RC' or @tip<>'RC' and (d.tip<>'RM' or d.jurnal<>'RC'))
	and (@numar='' or d.numar like @numar)
	and (@f_numar='' or d.numar like @f_numar + '%' )
	and d.data between @f_data_jos and @f_data_sus
	and (@data is null or d.data=@data)
	and (@f_gestiune='' or d.cod_gestiune like @f_gestiune + '%' )
	and (@f_denumire_gestiune='' or left(isnull(gPred.denumire_gestiune, ''), 30) like '%' + replace(@f_denumire_gestiune,' ','%') + '%')
	and (@tip_doc not in ('TE', 'DF', 'PF') or @f_gestiune_primitoare='' or d.gestiune_primitoare like isnull(@f_gestiune_primitoare, '') + '%') 
	and (@f_denumire_gestiune_primitoare='' or left(isnull(gPrim.denumire_gestiune, ''), 30) like '%' + @f_denumire_gestiune_primitoare + '%')
	and (@f_tert='' or d.cod_tert like @f_tert + '%')
	and (@f_denumire_tert='' or isnull(t.denumire, '') like '%' + replace(@f_denumire_tert,' ','%') + '%' )
	and (@f_comanda='' or d.comanda like @f_comanda + '%')
	and (@f_denumire_comanda='' or isnull(com.descriere, '') like '%' + @f_denumire_comanda + '%')
	and (@f_lm='' or d.loc_munca like @f_lm + '%')
	and (@f_denumire_lm='' or isnull(lm.denumire, '') like '%' + @f_denumire_lm + '%')
	and (@f_valoare_minima=-99999999999 or (d.valoare+d.Tva_22) >= @f_valoare_minima)
	and (@f_valoare_maxima=99999999999 or (d.valoare+d.Tva_22) <= @f_valoare_maxima)
	and (@tip_doc in ('AS', 'RS','PF','CI','AF') or @lista_gestiuni=0 or gu.valoare is not null or gpu.Valoare is not null)
	and (@tip_doc not in ('AP', 'AS','AF') or @lista_clienti=0 or /*cu.valoare is not null*/ exists (select * from @ClientiUser cu where cu.valoare=d.cod_tert))
	and (@lista_lm=0 or /*lu.cod is not null*/ exists (select * from LMFiltrare lu where lu.utilizator=@userASiS and lu.cod=d.Loc_munca )
		or gu.valoare is null and gpu.Valoare is not null) -- TI-urile sa nu tina cont de locul de munca, nefiind modificabile
	and (@f_factura='' or (case when @tip_doc in ('AI', 'AE', 'DF') then left(d.factura, 8)+left(d.Contractul, 8) else d.Factura end) like '%'+@f_factura + '%')
	and (@f_data_facturii_jos is null or d.data_facturii>=@f_data_facturii_jos)
	and (@f_data_facturii_sus is null or d.data_facturii<=@f_data_facturii_sus)
	and (@f_contractcor='' or isnull(con.contract_coresp, '') like @f_contractcor+'%')--/*SP
	and (@f_contract='' or d.Contractul like rtrim(@f_contract)+'%')--SP*/
	and (@f_stare='' or isnull(d.stare,'') like @f_stare+'%' or (case when d.stare in (2,6) then 'Definitiv' when d.stare = 1 then 'Anulat' when d.stare = 4 then 'Stornat' else 'Operat' end) like  @f_stare+'%')
--group by d.Subunitate, (case when d.tip='RM' and d.jurnal='RC' then 'RC' else d.tip end), d.tip,d.Numar, d.Data
order by d.data desc 

alter table #d100 add contcorespondent varchar(20),dencontcorespondent varchar(80),contvenituri varchar(20),dencontvenituri varchar(80),Numar_pozitii int,
	tcantitate decimal(17,3), valtotala_receptii decimal(17,2), tva_receptii decimal(15,2), tva decimal(15,2),valvaluta decimal(15,2)


update #d100 -- date din pozitiile documentului + denumiri de conturi
	set contcorespondent=rtrim(g.cont_corespondent),dencontcorespondent=rtrim(cc.Denumire_cont),contvenituri=rtrim(g.cont_venituri),dencontvenituri=rtrim(cv.denumire_cont),Numar_pozitii=g.nrp, 
		tcantitate=isnull(g.tcantitate,0), valtotala_receptii=isnull(g.valtotala,0), tva=/*tva_11+tva_22+isnull(tva_prestari,0)-*/isnull(g.tva_receptii,0),
		valvaluta=isnull(g.valvaluta,0)
		from 
		(select p.subunitate,p.tip,p.numar,p.data,max(p.Cont_corespondent) as cont_corespondent,max(p.cont_venituri) as cont_venituri,count(*) as nrp,  
			sum(p.cantitate) as tcantitate, 
			sum(case when p.tip in ('RM','RS','RC') then round(p.cantitate*p.pret_valuta,2)+p.TVA_deductibil else 0 end) as valtotala, -- variabila ciudata
			sum(case when p.tip in ('RM','RS','RC') and p.procent_vama=3 then p.TVA_deductibil else 0 end) as tva_receptii, -- la RM pret de stoc contine TVA nedeductibil, se scade din TVA
			sum(round(p.cantitate*p.pret_valuta,2)) as valvaluta
			from pozdoc p 
			inner join #d100 d on p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data
			group by p.subunitate,p.tip,p.numar,p.data) g
		left outer join conturi cc on cc.subunitate=g.subunitate and g.cont_corespondent=cc.cont
		left outer join conturi cv on cv.subunitate=g.subunitate and g.cont_venituri=cv.cont
	where #d100.subunitate=g.subunitate and #d100.tip=g.tip and #d100.numar=g.numar and #d100.data=g.data

select jd.tip,jd.numar,max(jd.idJurnal) as idJurnal
into #j100
from #d100
inner join JurnalDocumente jd on #d100.tip=jd.tip and jd.numar=#d100.Numar
group by jd.tip,jd.numar

select 
	rtrim(d.subunitate) as subunitate, rtrim(case when d.tip='RM' and d.jurnal='RC' then 'RC' else d.tip end) as tip, 
	rtrim(d.numar) as numar, rtrim(d.numar) as numarf, -- @numarf este numarul folosit ca manevra pentru schimbare in procedura specifica 
	convert(char(10),d.data,101) as data, convert(char(10),d.data,101) as dataf, -- idem
	rtrim(isnull(gPred.denumire_gestiune,'')) as dengestiune, rtrim(d.cod_gestiune) as gestiune, 
	rtrim(isnull(t.denumire,'')) as dentert, rtrim(d.cod_tert) as tert, rtrim(d.factura) as factura, 
	rtrim(d.contractul) as contract, rtrim(isnull(lm.denumire,'')) as denlm, rtrim(d.loc_munca) as lm, 
	isnull(rtrim(com.descriere),'') as dencomanda, 

	---despartire camp comanda in comanda(primele 20 caractere) si indicator bugetar(ultimele 20 caractere)----
	rtrim(left(d.comanda,20)) as comanda,  rtrim(substring(d.comanda,21,20)) as indbug,
	isnull(substring(indb.indbug,1,2),'  ')+'.'+isnull(substring(indb.indbug,3,2),'  ')+'.'+isnull(substring(indb.indbug,5,2),'  ')+'.'+isnull(substring(indb.indbug,7,2),'  ')+'.'
		+isnull(substring(indb.indbug,9,2),'  ')+'.'+isnull(substring(indb.indbug,11,2),'  ')+'.'+isnull(substring(indb.indbug,13,2),'  ')+' - '+rtrim(ltrim(indb.denumire)) as denbug,

	---daca documentul este transfer atunci campul gestiune_primitoare din doc este gestiunea primitoare, altfel in acest camp se salveaza punctul de livrare----
	---daca documentul este dare in folosinta campul gestiune_primitoare din doc este folosit pt salvarea marcii catre care se face darea in folosinta-----
	(case when d.tip in ('TE','DF','PF') then isnull(rtrim(d.gestiune_primitoare),'') else '' end) as gestprim,isnull(rtrim(gPrim.denumire_gestiune),'') as dengestprim, 
	(case when d.tip in ('AP', 'AS', 'AC') then isnull(rtrim(d.gestiune_primitoare),'') else '' end) as punctlivrare,rtrim(isnull(tpctliv.descriere, '')) as denpunctlivrare, 

	rtrim(d.valuta) as valuta,rtrim(v.Denumire_valuta) as denvaluta, convert(decimal(13,4), d.curs) as curs, 

	convert(decimal(17,3), d1.tcantitate) as tcantitate, 
	convert(decimal(17,2), d.valoare) as valoare, 
	convert(decimal(15,2), d.tva_11) as tva11, convert(decimal(15,2),d.tva_22) as tva22, 
	convert(decimal(15,2), d.tva_11+d.tva_22) as tvatotala, 
	convert(decimal(17,2),d.valoare)+ convert(decimal(15,2),d.tva_11+d.tva_22)+ convert(decimal(15,2),d1.tva)	as valtotala, 
	convert(decimal(15,2),d.valoare_valuta) as valoarevaluta, 
	(case when d.Valuta='' then convert(decimal(15,2),d.valoare)+convert(decimal(15,2),d.tva_11+d.tva_22) else convert(decimal(15,2),d.valoare_valuta) end) as totalvaloare, 
	convert(decimal(17,2), isnull(d1.valtotala_receptii,0)) as valvalutacutva, -- variabila ciudata
	convert(decimal(17,2), isnull(d1.valvaluta,0)) as valvaluta,
	---in campul discount_suma, se salveaza categoria de pret 
	convert(int,d.Discount_suma) as categpret, rtrim(cpret.denumire)as dencatpret,

	---in functie de contul facturi se aduce bifa de factura nesosita,pentru receptii
	(case when d.Tip in ('RM','RS','RC') and d.Cont_factura like'%408' then 1 else 0 end ) as facturanesosita, 

	---in functie de contul facturi se aduce bifa de aviz nefacturat, pentru avize
	(case when d.Tip in ('AP','AS') and d.Cont_factura =@ContAvizNefacturat then 1 else 0 end ) as aviznefacturat, 

	convert(decimal(15,2), d.cota_tva) as cotatva,  convert(decimal(15,2), d.discount_p) as discount, convert(decimal(15,2), d.discount_suma) as sumadiscount,

	---campul cota_tva din doc se foloseste pentru tipul TVA-ului-------
	convert(varchar,convert(int,d.cota_tva)) as tiptva,
	(case when @tip in ('RM','RC','RS') and d.cota_tva=0 then '0-TVA Deductibil'
												when @tip in ('RM','RC','RS') and d.cota_tva=1 then '1-TVA Compensat'
												when @tip in ('RM','RC','RS') and d.cota_tva=2 then '2-TVA Nedeductibil'
												when @tip in ('AP', 'AS', 'AC') and d.cota_tva=0 then '0-TVA Colectat' 
												when @tip in ('AP', 'AS', 'AC') and d.cota_tva=1 then '1-TVA Compensat' 
												when @tip in ('AP', 'AS', 'AC') and d.cota_tva=2 then '2-TVA Neinregistrat' else '' end ) as denTiptva,

	---in cazul AP si AS campul numar_dvi este refolosit pentru salvarea explicatiilor de pe antet
	rtrim(case when d.tip in ('AI', 'AE', 'DF','AF') then left(d.factura, 8)+left(d.Contractul, 8) 
		when d.tip in ('AS','AP','RS') then rtrim(d.Numar_DVI) else '' end) as explicatii,
	rtrim(d.numar_dvi) as numardvi, 		
	 
	cast(cast(d.pro_forma as bit) as int) as proforma, 
	rtrim(d.tip_miscare) as tipmiscare,
	rtrim(d.cont_factura) as contfactura, 
	rtrim(d.cont_factura)+'-'+rtrim(isnull(cf.Denumire_cont, '')) as dencontfactura, 
	d1.contcorespondent as contcorespondent, 
	d1.dencontcorespondent as dencontcorespondent, 
	d1.contvenituri as contvenituri, 
	d1.dencontvenituri as dencontvenituri, 
	convert(char(10),d.Data_facturii,101) as datafacturii, convert(char(10),d.Data_scadentei,101) as datascadentei,
	datediff(DAY,d.Data,d.Data_scadentei) as zilescadenta, --zilele de scadenta se calculeaza din data scadentei 
	rtrim(d.jurnal) as jurnal, 
	--sum(case when p.Numar is null then 0 else 1 end) as numarpozitii, 
	d1.Numar_pozitii as numarpozitii, 
	rtrim(isnull(ad.numele_delegatului,'')) as numedelegat,  
	rtrim(isnull(ad.seria_buletin,'')) as seriabuletin,
	rtrim(isnull(ad.numar_buletin,'')) as numarbuletin,
	rtrim(isnull(ad.eliberat,'')) as eliberat,
	rtrim(isnull(ad.mijloc_de_transport,'')) as mijloctp,
	rtrim(isnull(ad.numarul_mijlocului,'')) as nrmijloctp,
	convert(char(10), isnull(ad.data_expedierii, ''), 101) as dataexpedierii, 
	isnull(ad.ora_expedierii, '') as oraexpedierii,
	rtrim(isnull(ad.observatii,'')) as observatii,
	rtrim(isnull(ad.punct_livrare,'')) as punctlivareexped,
	rtrim(isnull(con.Contract_coresp,'')) as contractcor,
	rtrim(d.stare) as stare, 
	(case when d.stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or 
		(d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then 'Definitiv' 
		when d.stare = 1 then 'Anulat' when d.stare = 4 then 'Stornat' else 'Operat' end)  as denStare,
	--(case when d.stare = 2 then '#0B0B61' 
	(CASE when sd.culoare is not null then sd.culoare 
	else
	(case when d.stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or 
		(d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then '#808080' 
			when d.stare = 1 then '#660066'/*'#FF8040'*/ when d.stare = 4 then '#0B3B24' 
		--when d.stare = 5 then '#408080' -- stare=3 inseamna operat direct, stare=5 inseamna generat din PV sau din alta aplicatie 
		when d.Valoare <= 0 then'#FF0000' else '#000000' end) end)  as culoare,
	--cele care vin din PVria trebuie sa fie definitive.
	(case when d.Stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or (d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then 1 else 0 end) as _nemodificabil
	--pentru tabul de inregitrari contabile
	,RTRIM(d.tip) tipdocument,RTRIM(d.numar) nrdocument,
	jd.stare as Stare1
into #doc
from #d100 d1 
	inner join doc d on d1.subunitate=d.subunitate and d1.tip=d.tip and d1.numar=d.numar and d1.data=d.data
	left outer join terti t on t.subunitate = @sub and t.tert = d.cod_tert 
	left outer join #gest gPred on gPred.cod_gestiune = d.cod_gestiune and gPred.tip_gestiune=(case when @tip_doc in ('PF','CI','AF') then 'F' else 'G' end)
	left outer join #gest gPrim on gPrim.cod_gestiune = d.gestiune_primitoare and gPrim.tip_gestiune=(case when @tip_doc='TE' then 'G' else 'F' end)
	left outer join lm on lm.cod = d.loc_munca
	left outer join comenzi com on com.subunitate = @sub and com.comanda = left(d.comanda,20)  
	left outer join indbug indb on indb.Indbug = substring(d.comanda,21,20)
	left outer join @GestiuniUser gu on gu.valoare=d.Cod_gestiune
	left outer join @GestiuniUser gpu on @tip_doc='TE' and gpu.valoare=d.Gestiune_primitoare
	left outer join conturi cf on @tip_doc not in ('PP', 'CM', 'PF', 'CI', 'AF') and cf.Subunitate=@sub and cf.Cont=d.Cont_factura
	left outer join infotert tpctliv on @tip_doc in ('AP','AS','AC') and tpctliv.Subunitate=@sub and tpctliv.Tert=d.cod_tert and tpctliv.identificator=d.gestiune_primitoare
	left outer join categpret cpret on cpret.Categorie=d.Discount_suma
	left outer join anexadoc ad on ad.Subunitate=@sub and ad.Tip=@tip_doc and ad.Numar=d.Numar and ad.Data=d.Data and ad.Tip_anexa=''
	left outer join con on d.Contractul=con.Contract and d.Data=con.Data and con.Tip='BK' and con.Subunitate=@Sub
	left outer join incfact inf on @facturiDefinitive=1 and @tip_doc='AP' and inf.subunitate=@sub and inf.Numar_factura=d.factura and inf.Numar_pozitie=1
	left outer join valuta v on v.Valuta=d.Valuta
	left outer join #j100 on d1.tip=#j100.tip and d1.numar=#j100.numar
	left outer join JurnalDocumente jd on jd.idJurnal=#j100.idJurnal
	LEFT OUTER JOIN StariDocumente sd on jd.tip=sd.tipDocument and jd.stare=sd.stare
order by d.data desc 

IF EXISTS (
		SELECT 1
		FROM syscolumns sc, sysobjects so
		WHERE so.id = sc.id
			AND so.NAME = 'doc'
			AND sc.NAME = 'detalii'
		)
BEGIN
	--SET @areDetalii = 1

	ALTER TABLE #doc ADD detalii XML
	update dd set detalii=d.detalii
	from #doc dd inner join doc d on dd.subunitate=d.subunitate and dd.tip=d.tip and dd.data=d.data and dd.numar=d.numar
end
select * from #doc
for xml raw
select 1 areDetaliiXml for xml raw, root('Mesaje')

if object_id('tempdb..#doc') is not null drop table #doc
if object_id('tempdb..#gest') is not null drop table #gest

end try
begin catch
	set @mesaj =ERROR_MESSAGE()+' (wIaDocSP)'
	raiserror(@mesaj,11,1)
end catch