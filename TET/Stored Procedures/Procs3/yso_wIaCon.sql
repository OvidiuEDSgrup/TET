--***
create procedure yso_wIaCon @sesiune varchar(50), @parXML xml as  
  
declare @subunitate varchar(20), @userASiS varchar(20), @iDoc int, 
@lista_gestiuni bit, @lista_clienti bit, @lista_lm bit, @lista_gbk bit, @f_comspec char(1),@period_antet int

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
IF @userASiS IS NULL
	RETURN -1
	
declare @areDetalii int

select @lista_gestiuni=0, @lista_gbk=0, @lista_clienti=0--, @lista_lm=0
select @lista_gestiuni=(case when cod_proprietate='GESTIUNE' then 1 else @lista_gestiuni end), 
	@lista_gbk=(case when cod_proprietate='GESTBK' then 1 else @lista_gbk end), 
	@lista_clienti=(case when cod_proprietate='CLIENT' then 1 else @lista_clienti end) 
	--, @lista_lm=(case when cod_proprietate='LOCMUNCA' then 1 else @lista_lm end)
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'GESTBK', 'CLIENT', 'LOCMUNCA') and valoare<>''

select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'
select @period_antet=val_alfanumerica from par where tip_parametru='UC' and parametru='PERIODCON'
if OBJECT_ID('tempdb..#wcon') is not null
	drop table #wcon

exec sp_xml_preparedocument @iDoc output, @parXML
select top 100 
rtrim(d.subunitate) as subunitate, rtrim(d.tip) as tip, rtrim(d.Contract) as numar, convert(varchar(10),d.data,101) as data, 
rtrim(d.Explicatii) as explicatii, convert(varchar(10),d.termen,101) as termen, 
isnull(rtrim(left(gPred.denumire_gestiune,30)),'') as dengestiune, rtrim(d.gestiune) as gestiune,  
rtrim(isnull(t.denumire,'')) as dentert, rtrim(d.factura) as factura, 
rtrim(d.Tert) as tert, rtrim(contract_coresp) as contractcor, rtrim(d.Punct_livrare) as punctlivrare, 
isnull(rtrim(lm.denumire),'') as denlm, rtrim(d.loc_de_munca) as lm,
isnull(rtrim(left(gPrim.denumire_gestiune,30)),'') as dengestprim, rtrim(d.Cod_dobanda) as gestprim, 
rtrim(d.valuta) as valuta, convert(decimal(13,4),d.curs) as curs, /*sp
convert(decimal(15,2),d.total_contractat-d.total_tva) as valoare, 
convert(decimal(15,2),d.total_tva) as valtva, 
convert(decimal(15,2),d.total_contractat) as valtotala, --sp*/ yp.*,
rtrim(isnull(d.Scadenta,'')) as scadenta,
rtrim(isnull(ext.camp_1,'')) as contclient,
rtrim(isnull(ext.camp_2,'')) as procpen,
rtrim(isnull(ext.camp_3,'')) as contr_cadru,
rtrim(isnull(ext.camp_4,'')) as ext_camp4,
convert(varchar(10),ext.Camp_5,101) as ext_camp5,
rtrim(isnull(ext.modificari,'')) as ext_modificari,
rtrim(isnull(ext.Clauze_speciale,'')) as ext_clauze,
convert(varchar(10),d.Data_rezilierii,101)as valabilitate,
convert(int,(select count(1) from pozcon p where p.subunitate=d.subunitate and p.tip=d.tip and p.contract=d.contract and p.data=d.data)) as pozitii, 
(case when d.tip in ('BF', 'FA') then d.discount else 0 end) as discount, 
(case when left(d.mod_plata,1)='1' then '1' else '0' end) as comspec,
--(case	when @period_antet='0' then (case when left(d.mod_plata,1)='1' then '1' else '0' end) 
--		else (case when d.mod_plata='1' then 'Trimestrial' when d.mod_plata='2' then 'Semestrial'when d.mod_plata='3' then 'Anual' end) 
--end) as comspec, 
rtrim(d.stare) as stare, 
--(case when @areDetalii=1 then '' else null end) as detalii, 
--( case when @aredetalii='' then  d.detalii else '' end) as detalii,
d.stare + '-' + (case when isnull(pa.val_alfanumerica, '')<>'' then rtrim(pa.val_alfanumerica) else (case d.Stare when '0' then 'Operat' when '1' then 'Definitiv' when '2' then 'Blocat' when '3' then 'Confirmat' when '4' then 'Expediat' when '5' then 'In vama' when '6' then 'Realizat' when '7' then 'Reziliat' else d.stare end) end) as denstare, 
RTrim(d.Mod_penalizare) as info1, convert(decimal(15,2),d.Val_reziduala) as info2, d.Sold_initial as info3, d.Procent_penalizare as info4, 
(case when d.Tip not in ('BF', 'FA') then d.discount else 0 end) as info5, 
--RTRIM(case when d.Tip not in ('BF', 'FA') then d.Responsabil else '' end) as info6,
rtrim(isnull(d.responsabil,'')) as info6,
(case d.Stare when '0' then '#000000' when '1' then '#0000FF' when '4' then '#408080' else '#808080' end) as culoare, 
(case d.Stare when '0' then 0 else 1 end) as _nemodificabil
into #wcon
from con d 
cross join OPENXML(@iDoc, '/row')
	WITH
	(
		tip varchar(2) '@tip',
		numar varchar(20) '@numar',
		data datetime '@data',
		scadenta varchar(10)'@scadenta',
		data_rezilierii datetime '@valabilitate',
		data_jos datetime '@datajos',
		data_sus datetime '@datasus',
		fnumar varchar(20) '@f_numar',
		gestiune varchar(9) '@f_gestiune',
		denumire_gestiune varchar(30) '@f_dengestiune',
		gestiune_primitoare varchar(9) '@f_gestprim',
		denumire_gestiune_primitoare varchar(30) '@f_dengestprim',
		stare varchar(13) '@f_stare',
		tert varchar(13) '@f_tert',
		denumire_tert varchar(80) '@f_dentert',
		lm varchar(9) '@f_lm',
		denumire_lm varchar(30) '@f_denlm',
		valoare_minima float '@f_valoarejos',
		valoare_maxima float '@f_valoaresus',
		punctlucru varchar(20)'@f_punctlucru', 
		info6 varchar(20)'@f_info6', 
		fcomspec varchar(20)'@f_comspec', 
		contractcor varchar(20)'@f_contractcor',
		an varchar(20)'@f_an'
	) as fx
--/*sp
outer apply 
	(select cantcomandata=convert(decimal(15,2),sum(round(convert(decimal(17, 5), p.cantitate),2)))
		,cantaprobata=convert(decimal(15,2),sum(round(convert(decimal(17, 5), p.Cant_aprobata),2)))
		,canttransferata=convert(decimal(15,2),sum(round(convert(decimal(17, 5), p.Pret_promotional),2)))
		,cantrealizata=convert(decimal(15,2),sum(round(convert(decimal(17, 5), p.Cant_realizata),2)))
		,valoare=convert(decimal(15,2),sum(round(p.valCuDisc,2)))
		,valtva=convert(decimal(15,2),sum(round(p.valTva,2)))
		,valtotala=convert(decimal(15,2),sum(round(p.valCuTva,2)))
	from yso_pozConExp p
	where p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Contract=d.Contract and p.Data=d.Data and p.Tert=d.Tert) yp
--sp*/
left join par pa on pa.tip_parametru='UC' and pa.parametru='STAREBK'+d.stare
left outer join terti t on t.subunitate = d.subunitate and t.tert = d.tert 
left outer join gestiuni gPred on gPred.subunitate = d.subunitate and gPred.cod_gestiune = d.gestiune 
left outer join gestiuni gPrim on gPrim.subunitate = d.subunitate and gPrim.cod_gestiune = d.Cod_dobanda 
left outer join lm on lm.cod = d.loc_de_munca 
left outer join extcon ext on ext.subunitate=d.subunitate and ext.Tip=d.Tip and ext.contract=d.contract and ext.Data=d.Data and ext.tert=d.tert and ext.Numar_pozitie=1
left outer join proprietati gu on gu.valoare=d.gestiune and gu.tip='UTILIZATOR' and gu.cod=@userASiS and gu.cod_proprietate='GESTIUNE'
left outer join proprietati gpu on d.Tip in ('BF', 'BK', 'BP') and gpu.valoare=d.Cod_dobanda and gpu.tip='UTILIZATOR' and gpu.cod=@userASiS and gpu.cod_proprietate='GESTBK'
left outer join proprietati cu on cu.valoare=d.tert and cu.tip='UTILIZATOR' and cu.cod=@userASiS and cu.cod_proprietate='CLIENT'
left outer join LMFiltrare lu on lu.utilizator=@userASiS and d.Loc_de_munca=lu.cod
where d.subunitate=@subunitate 
and d.tip = fx.tip 
and (d.Data=fx.data or ISNULL(fx.data,'')='')
and (d.contract=fx.numar or isnull(fx.numar,'')='')
--and d.contract like isnull(fx.numar, '')+'%' 
and d.contract like isnull(fx.fnumar, '')+'%' 
and (year(d.Data) like fx.an+'%' or isnull(fx.an,'')='')--sa tina cont de filtru pe an 
and d.data between isnull(fx.data_jos, '01/01/1901') and (case when isnull(fx.data_sus, '01/01/1901')<='01/01/1901' then '12/31/2999' else fx.data_sus end)
and d.gestiune like isnull(fx.gestiune, '') + '%' 
and left(isnull (gPred.denumire_gestiune, ''), 30) like '%' + isnull(fx.denumire_gestiune, '') + '%'
and d.Cod_dobanda like isnull(fx.gestiune_primitoare, '') + '%' 
and left(isnull(gPrim.denumire_gestiune, ''), 30) like '%' + isnull(fx.denumire_gestiune_primitoare, '') + '%'
and d.tert like isnull(fx.tert, '') + '%'
and isnull(t.denumire, '') like '%' + isnull(Replace(fx.denumire_tert,' ','%'), '') + '%'
and d.loc_de_munca like isnull(fx.lm, '') + '%'
and isnull(lm.denumire, '') like '%' + isnull(fx.denumire_lm, '') + '%'
and (isnull(rtrim(pa.val_alfanumerica),'') like '%' + isnull(fx.stare, '') + '%' or rtrim(d.stare) like '%' + isnull(fx.stare, '') + '%')
and d.total_contractat between isnull(fx.valoare_minima, -99999999999) and isnull(fx.valoare_maxima, 99999999999)
and ((d.tip<>'BK' or @lista_gestiuni=0 or gu.valoare is not null or d.Gestiune='') 
or (d.tip='BK' 
	and (@lista_gestiuni=0 or (gu.valoare is not null and @lista_gbk=0) or d.Gestiune='' -- daca Gestiunea este in lista proprie de GESTIUNE si nu are GESTBK
	or gpu.Valoare is not null and d.Cod_dobanda<>''))) -- sau daca Gestiunea primitoare este GESTBK
and (d.tip not in ('BK', 'BP') or @lista_clienti=0 or cu.valoare is not null)
--and (@lista_lm=0 or exists (select 1 from proprietati lu where RTrim(d.loc_de_munca) like RTrim(lu.valoare)+'%' and lu.tip='UTILIZATOR' and lu.cod=@userASiS and lu.cod_proprietate='LOCMUNCA'))
and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null or d.tip='BK' and gu.Valoare is not null)
and d.responsabil like '%'+isnull(fx.info6, '')+'%' 
and d.contract_coresp like isnull(fx.contractcor, '')+'%'
and (fx.fcomspec is null or (case when left(d.mod_plata,1)='1' then '1' else '0' end)=fx.fcomspec)
order by data desc 

if exists(select 1 from syscolumns sc,sysobjects so where so.id=sc.id and so.name='con' and sc.name='detalii')  
begin  
	set @areDetalii=1  
	alter table #wcon add detalii xml  
	update #wcon set detalii=con.detalii 
	from con where #wcon.subunitate=con.subunitate and #wcon.tip=con.Tip and #wcon.numar=con.contract and #wcon.data=con.data 
end  
else  
 set @areDetalii=0  
 
select @areDetalii as areDetaliiXml for xml raw, root ('Mesaje')      
select * from #wcon 
for xml raw

exec sp_xml_removedocument @iDoc 
