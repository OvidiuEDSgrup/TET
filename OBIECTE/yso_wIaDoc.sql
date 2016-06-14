--***
if exists (select * from sysobjects where name ='yso_wIaDoc')
drop procedure yso_wIaDoc
go
--***
create procedure yso_wIaDoc @sesiune varchar(50), @parXML xml
as

set transaction isolation level read uncommitted
declare @Sub char(9), @userASiS varchar(10),@iDoc int, @facturiDefinitive int, 
	@lista_gestiuni bit, @lista_clienti bit, @lista_lm bit,@CTCLAVRT bit,@ContAvizNefacturat varchar(20)

exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec luare_date_par 'GE','FACTDEF',@facturiDefinitive output,0,'' 

--select @userASiS=id from utilizatori where observatii=SUSER_NAME()
/*Modificare pentru login utilizator sa */
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
select @lista_gestiuni=0, @lista_clienti=0, @lista_lm=0
select @lista_gestiuni=(case when cod_proprietate='GESTIUNE' and Valoare<>'' then 1 else @lista_gestiuni end), 
	@lista_clienti=(case when cod_proprietate='CLIENT' and Valoare<>'' then 1 else @lista_clienti end), 
	@lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA')

exec sp_xml_preparedocument @iDoc output, @parXML

select 'G' as tip_gestiune, cod_gestiune, left(Denumire_gestiune,30) as Denumire_gestiune 
into #gest 
from gestiuni where Subunitate=@Sub 
union all 
select 'F', marca, nume from personal
CREATE UNIQUE CLUSTERED INDEX Idx1 ON #gest (tip_gestiune, cod_gestiune)

--declare @areDetalii int
--if exists(select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='doc' and sc.name='detalii')
--	set @areDetalii=1
--else
--	set @areDetalii=0

select top 100 
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
convert(decimal(15,2), d.valoare) as valoare, convert(decimal(15,2), d.tva_11) as tva11, convert(decimal(15,2),d.tva_22) as tva22, 
convert(decimal(15,2),d.tva_11+d.tva_22) as tvatotala, 
convert(decimal(15,2),d.tva_11)+convert(decimal(15,2),d.tva_22)+convert(decimal(15,2), d.valoare) as valtotala, 
convert(decimal(15,2),d.valoare_valuta) as valoarevaluta, 
(case when d.Valuta='' then convert(decimal(15,2),d.tva_11)+convert(decimal(15,2),d.tva_22)+convert(decimal(15,2), d.valoare) 
	else convert(decimal(15,2),d.valoare_valuta) end) as totalvaloare, 
	
isnull(convert(decimal(15,2),(select sum(p.cantitate*p.pret_cu_amanuntul) from pozdoc p where p.Subunitate=d.Subunitate and p.Tip=d.Tip
	and p.Numar=d.Numar and p.Data=d.Data) ),0) as valamanunt,

---in campul discount_suma, se salveaza categoria de pret 
convert(int,d.Discount_suma) as categpret, rtrim(cpret.denumire)as dencatpret,

---in functie de contul facturi se aduce bifa de factura nesosita,pentru receptii
(case when d.Tip in ('RM','RS','RC') and d.Cont_factura like'%408' then 1 else 0 end ) as facturanesosita, 

---in functie de contul facturi se aduce bifa de aviz nefacturat, pentru avize
(case when d.Tip in ('AP','AS') and d.Cont_factura =@ContAvizNefacturat then 1 else 0 end ) as aviznefacturat, 

convert(decimal(15,2), d.cota_tva) as cotatva,  convert(decimal(15,2), d.discount_p) as discount, convert(decimal(15,2), d.discount_suma) as sumadiscount,

---campul cota_tva din doc se foloseste pentru tipul TVA-ului-------
convert(varchar,d.cota_tva) as tiptva,(case when fx.tip in ('RM','RC','RS') and d.cota_tva=0 then '0-TVA Deductibil'
											when fx.tip in ('RM','RC','RS') and d.cota_tva=1 then '1-TVA Compensat'
											when fx.tip in ('RM','RC','RS') and d.cota_tva=2 then '2-TVA Nedeductibil'
											when fx.tip in ('AP', 'AS', 'AC') and d.cota_tva=0 then '0-TVA Colectat' 
											when fx.tip in ('AP', 'AS', 'AC') and d.cota_tva=1 then '1-TVA Compensat' 
											when fx.tip in ('AP', 'AS', 'AC') and d.cota_tva=2 then '2-TVA Neinregistrat' else '' end ) as denTiptva,

---in cazul AP si AS campul numar_dvi este refolosit pentru salvarea explicatiilor de pe antet
rtrim(case when d.tip in ('AI', 'AE', 'DF','AF') then left(d.factura, 8)+left(d.Contractul, 8) when d.tip in ('AS','AP') then rtrim(d.Numar_DVI) else '' end) as explicatii,
rtrim(d.numar_dvi) as numardvi, 		
 
cast(cast(d.pro_forma as bit) as int) as proforma, rtrim(d.tip_miscare) as tipmiscare,
rtrim(d.cont_factura) as contfactura, rtrim(d.cont_factura)+'-'+rtrim(isnull(cf.Denumire_cont, '')) as dencontfactura, 
rtrim(isnull((select top 1 p.Cont_corespondent from pozdoc p where p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data), '')) as contcorespondent, 
rtrim(isnull((select top 1 cc.Denumire_cont from conturi cc, pozdoc p where d.tip not in ('RM', 'RS') and p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data and cc.Subunitate=p.Subunitate and cc.Cont=p.Cont_corespondent), '')) as dencontcorespondent, 
rtrim(isnull((select top 1 p.Cont_venituri from pozdoc p where p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data), '')) as contvenituri, 
rtrim(isnull((select top 1 tcv.Denumire from terti tcv, pozdoc p where d.Tip='AI' and p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data and tcv.Subunitate=p.Subunitate and tcv.Tert=p.cont_venituri), isnull((select top 1 cc.Denumire_cont from conturi cc, pozdoc p where d.tip not in ('AI', 'PF', 'CI', 'AF') and p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data and cc.Subunitate=p.Subunitate and cc.Cont=p.Cont_venituri), ''))) as dencontvenituri, 
convert(char(10),d.Data_facturii,101) as datafacturii, convert(char(10),d.Data_scadentei,101) as datascadentei,
datediff(DAY,d.Data,d.Data_scadentei) as zilescadenta, --zilele de scadenta se calculeaza din data scadentei 
rtrim(d.jurnal) as jurnal, 
--sum(case when p.Numar is null then 0 else 1 end) as numarpozitii, 
convert(int,d.Numar_pozitii) as numarpozitii, 
--isnull(convert(decimal(15,2),sum(p.cantitate*preturi.pret_cu_amanuntul)),0) 
0 as valamcatprimitor, -- se va pune/lua in doc.detalii (XML) la Salconserv (vezi mai sus)
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
--(select top 1 detalii from doc dx where dx.Subunitate=d.subunitate and dx.Tip=d.Tip and dx.Numar=d.Numar and dx.Data=d.data) as detalii,
--(case when @areDetalii=1 then '' else null end) as detalii, 
rtrim(d.stare) as stare, 
(case when d.stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or 
	(d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then 'Definitiv' 
	when d.stare = 1 then 'Anulat' when d.stare = 4 then 'Stornat' else 'Operat' end)  as denStare,
--(case when d.stare = 2 then '#0B0B61' 
(case when d.stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or 
	(d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then '#808080' 
		when d.stare = 1 then '#FF8040'/*'#787878'*/ when d.stare = 4 then '#0B3B24' 
	--when d.stare = 5 then '#408080' -- stare=3 inseamna operat direct, stare=5 inseamna generat din PV sau din alta aplicatie 
	when d.Valoare <= 0 then'#FF0000' else '#000000' end)  as culoare,
--cele care vin din PVria trebuie sa fie definitive.
(case when d.Stare in (2,6) or d.jurnal='MFX' or inf.mod_tp='D' or (d.tip='TE' and @lista_gestiuni=1 and gu.valoare is null and gpu.Valoare is not null) then 1 else 0 end) as _nemodificabil
--pentru tabul de inregitrari contabile
,RTRIM(d.tip) tipdocument,RTRIM(d.numar) nrdocument
from doc d
cross join OPENXML(@iDoc, '/row')
	WITH
	(
		tip varchar(2) '@tip',
		numar varchar(8) '@numar',
		data_jos datetime '@datajos',
		data_sus datetime '@datasus',
		data datetime '@data', 
		fnumar varchar(8) '@f_numar',
		gestiune varchar(9) '@f_gestiune',
		denumire_gestiune varchar(30) '@f_dengestiune',
		gestiune_primitoare varchar(9) '@f_gestprim',
		denumire_gestiune_primitoare varchar(30) '@f_dengestprim',
		tert varchar(13) '@f_tert',
		denumire_tert varchar(80) '@f_dentert',
		dencontvenituri varchar(80) '@f_dencontvenituri',
		comanda varchar(20) '@f_comanda',
		denumire_comanda varchar(80) '@f_dencomanda',
		lm varchar(9) '@f_lm',
		denumire_lm varchar(30) '@f_denlm',
		valoare_minima float '@f_valoarejos',
		valoare_ima float '@f_valoaresus', 
		factura varchar(20) '@f_factura', 
		data_facturii_jos datetime '@f_datafacturiijos', 
		data_facturii_sus datetime '@f_datafacturiisus',
		contractcor varchar(20)'@f_contractcor',
		fstare varchar(20)'@f_stare'

	) as fx 
--left outer join pozdoc p on p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Numar=d.Numar and p.Data=d.Data
left outer join terti t on t.subunitate = d.subunitate and t.tert = d.cod_tert 
left outer join #gest gPred on gPred.cod_gestiune = d.cod_gestiune and gPred.tip_gestiune=(case when d.tip in ('PF','CI','AF') then 'F' else 'G' end)
left outer join #gest gPrim on gPrim.cod_gestiune = d.gestiune_primitoare and gPrim.tip_gestiune=(case when d.tip='TE' then 'G' else 'F' end)
left outer join lm on lm.cod = d.loc_munca 
left outer join comenzi com on com.subunitate = d.subunitate and com.comanda = left(d.comanda,20)  
left outer join indbug indb on indb.Indbug = substring(d.comanda,21,20)
left outer join proprietati gu on gu.valoare=d.cod_gestiune and gu.tip='UTILIZATOR' and gu.cod=@userASiS and gu.cod_proprietate='GESTIUNE'
left outer join proprietati gpu on d.tip='TE' and gpu.valoare=d.Gestiune_primitoare and gpu.tip='UTILIZATOR' and gpu.cod=@userASiS and gpu.cod_proprietate='GESTIUNE'
left outer join proprietati cu on cu.valoare=d.cod_tert and cu.tip='UTILIZATOR' and cu.cod=@userASiS and cu.cod_proprietate='CLIENT'
left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=d.Loc_munca 
--left outer join conturi cc on d.tip not in ('RM', 'RS') and cc.Subunitate=p.Subunitate and cc.Cont=p.Cont_corespondent
left outer join conturi cf on d.tip not in ('PP', 'CM', 'PF', 'CI', 'AF') and cf.Subunitate=d.Subunitate and cf.Cont=d.Cont_factura
--left outer join conturi cv on d.tip not in ('AI', 'PF', 'CI', 'AF') and cv.Subunitate=p.Subunitate and cv.Cont=p.Cont_venituri
--left outer join terti tcv on d.Tip='AI' and tcv.Subunitate=p.Subunitate and tcv.Tert=p.cont_venituri
left outer join infotert tpctliv on d.tip='AP' and tpctliv.Subunitate=d.Subunitate and tpctliv.Tert=d.cod_tert and tpctliv.identificator=d.gestiune_primitoare
left outer join categpret cpret on cpret.Categorie=d.Discount_suma
left outer join anexadoc ad on ad.Subunitate=d.Subunitate and ad.Tip=d.Tip and ad.Numar=d.Numar and ad.Data=d.Data and ad.Tip_anexa=''
--left outer join proprietati prop on prop.Cod_proprietate='CATEGPRET' and prop.tip='GESTIUNE' and prop.cod=d.Gestiune_primitoare
--left outer join preturi on preturi.UM=prop.Valoare and preturi.Cod_produs=p.Cod and preturi.Data_superioara='2999-01-01' 
left outer join con on d.Numar=con.Contract and d.Data=con.Data and con.Tip='BK'
left outer join incfact inf on @facturiDefinitive=1 and d.tip='AP' and inf.subunitate=d.Subunitate and inf.Numar_factura=d.factura and inf.Numar_pozitie=1
left outer join valuta v on v.Valuta=d.Valuta
where d.subunitate=@Sub --and d.Jurnal<>'MFX' 
and d.tip = (case when fx.tip='RC' then 'RM' else fx.tip end) 
and (fx.tip='RC' and d.jurnal='RC' or fx.tip<>'RC' and (d.tip<>'RM' or d.jurnal<>'RC'))
and d.numar like isnull(fx.numar, '') + '%' 
and d.numar like isnull(fx.fnumar, '') + '%' 
and d.data between isnull(fx.data_jos, '01/01/1901') and (case when isnull(fx.data_sus, '01/01/1901')<='01/01/1901' then '12/31/2999' else fx.data_sus end)
and (fx.data is null or d.data=fx.data)
and d.cod_gestiune like isnull(fx.gestiune, '') + '%' 
and left(isnull(gPred.denumire_gestiune, ''), 30) like '%' + replace(isnull(fx.denumire_gestiune, ''),' ','%') + '%'
and (d.tip not in ('TE', 'DF', 'PF') or d.gestiune_primitoare like isnull(fx.gestiune_primitoare, '') + '%') 
and left(isnull(gPrim.denumire_gestiune, ''), 30) like '%' + isnull(fx.denumire_gestiune_primitoare, '') + '%'
and d.cod_tert like isnull(fx.tert, '') + '%'
and isnull(t.denumire, '') like '%' + replace(isnull(fx.denumire_tert, ''),' ','%') + '%'
--and (d.tip<>'AI' or isnull(tcv.denumire, '') like '%' + isnull(fx.dencontvenituri, '') + '%') -- va fi tratat cu subselect si aici...
and d.comanda like isnull(fx.comanda, '') + '%'
and isnull(com.descriere, '') like '%' + isnull(fx.denumire_comanda, '') + '%'
and d.loc_munca like isnull(fx.lm, '') + '%'
and isnull(lm.denumire, '') like '%' + isnull(fx.denumire_lm, '') + '%'
and (d.valoare+d.Tva_22) between isnull(fx.valoare_minima, -99999999999) and isnull(fx.valoare_ima, 99999999999)
and (d.tip in ('AS', 'RS','PF','CI','AF') or @lista_gestiuni=0 or gu.valoare is not null or gpu.Valoare is not null)
and (d.tip not in ('AP', 'AS','AF') or @lista_clienti=0 or cu.valoare is not null)
and (@lista_lm=0 or lu.cod is not null)
and (case when d.tip in ('AI', 'AE', 'DF') then left(d.factura, 8)+left(d.Contractul, 8) else d.Factura end) like '%'+ISNULL(fx.factura, '') + '%'
and d.data_facturii between isnull(fx.data_facturii_jos, '01/01/1901') and (case when isnull(fx.data_facturii_sus, '01/01/1901')<='01/01/1901' then '12/31/2999' else fx.data_facturii_sus end)
and (isnull(con.contract_coresp, '') like isnull(fx.contractcor, '')+'%')
and (fx.fstare is null or isnull(d.stare,'') like fx.fstare+'%' or (case when d.stare in (2,6) then 'Definitiv' when d.stare = 1 then 'Anulat' when d.stare = 4 then 'Stornat' else 'Operat' end) like  fx.fstare+'%')
--group by d.Subunitate, (case when d.tip='RM' and d.jurnal='RC' then 'RC' else d.tip end), d.tip,d.Numar, d.Data
order by d.data desc  
for xml raw

drop table #gest

exec sp_xml_removedocument @iDoc 
