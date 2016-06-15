--***
create procedure wIaCon @sesiune varchar(50), @parXML xml as  
set transaction isolation level read uncommitted
  
declare @subunitate varchar(20), @userASiS varchar(20), @iDoc int, @areDetalii int,
		@lista_gestiuni bit, @lista_clienti bit, @lista_gbk bit, @f_comspec char(1),@period_antet int,
		@tip varchar(2), @numar varchar(20), @data datetime, @data_rezilierii datetime, 
		@dataJos datetime, @dataSus datetime, @fNumar varchar(20), @fGestiune varchar(20), @fDenGestiune varchar(20),
		@fGestPrim varchar(20), @fDenGestPrim varchar(20), @fStare varchar(20), @fTert varchar(20), @fDenTert varchar(80),
		@fLm varchar(20), @fDenLm varchar(20), @fValoareJos float, @fValoareSus float, @fPunctLucru varchar(20),
		@fInfo6 varchar(20), @fComSpec varchar(20), @fContractCor varchar(20), @fAn varchar(20), @msgEroare varchar(2000),
		@filtruLocMuncaUtilizator bit
		
begin try

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

select	@tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),''),
		@data=@parXML.value('(/row/@data)[1]','datetime'),
		@data_rezilierii=@parXML.value('(/row/@valabilitate)[1]','datetime'),
		@dataJos=isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'01/01/1901'),
		@dataSus=isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'12/31/2999'),
		@fNumar=isnull(@parXML.value('(/row/@f_numar)[1]','varchar(20)'),''),
		@fGestiune=isnull(@parXML.value('(/row/@f_gestiune)[1]','varchar(20)'),''),
		@fDenGestiune=isnull(replace(@parXML.value('(/row/@f_dengestiune)[1]','varchar(20)'),' ','%'),''),
		@fGestPrim=isnull(@parXML.value('(/row/@f_gestprim)[1]','varchar(20)'),''),
		@fDenGestPrim=isnull(replace(@parXML.value('(/row/@f_dengestprim)[1]','varchar(20)'),' ','%'),''),
		@fStare=isnull(@parXML.value('(/row/@f_stare)[1]','varchar(20)'),''),
		@fTert=isnull(@parXML.value('(/row/@f_tert)[1]','varchar(20)'),''),
		@fDenTert=isnull(replace(@parXML.value('(/row/@f_dentert)[1]','varchar(80)'),' ','%'),''),
		@fLm=isnull(@parXML.value('(/row/@f_lm)[1]','varchar(20)'),''),
		@fDenLm=isnull(@parXML.value('(/row/@f_denlm)[1]','varchar(30)'),''),
		@fValoareJos=isnull(@parXML.value('(/row/@f_valoarejos)[1]','float'),-99999999999),
		@fValoareSus=isnull(@parXML.value('(/row/@f_valoaresus)[1]','varchar(20)'),99999999999),
		@fPunctLucru=isnull(@parXML.value('(/row/@f_punctlucru)[1]','varchar(20)'),''),
		@fInfo6=isnull(@parXML.value('(/row/@f_info6)[1]','varchar(20)'),''),
		@fComSpec=@parXML.value('(/row/@f_comspec)[1]','varchar(20)'),
		@fContractCor=isnull(@parXML.value('(/row/@f_contractcor)[1]','varchar(20)'),''),
		@fAn=isnull(@parXML.value('(/row/@f_an)[1]','varchar(20)'),'')
		
select	@lista_gestiuni=0, @lista_gbk=0, @lista_clienti=0,
		@filtruLocMuncaUtilizator=dbo.f_areLMFiltru(@userASiS)
		
select @lista_gestiuni=(case when cod_proprietate='GESTIUNE' then 1 else @lista_gestiuni end), 
	@lista_gbk=(case when cod_proprietate='GESTBK' then 1 else @lista_gbk end), 
	@lista_clienti=(case when cod_proprietate='CLIENT' then 1 else @lista_clienti end)
from proprietati 
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'GESTBK', 'CLIENT', 'LOCMUNCA') and valoare<>''

select	@subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @subunitate end),
		@period_antet=isnull((case when Parametru='CNAZBKBP' then Val_logica else @period_antet end),0)
	from par
	where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru ='PERIODCON')

if OBJECT_ID('tempdb..#wcon') is not null
	drop table #wcon

declare @clienti table(tert varchar(13) primary key)
insert into @clienti
select RTRIM(valoare)
from proprietati p
where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CLIENT' and valoare<>''

select top 100 
	rtrim(d.subunitate) as subunitate, rtrim(d.tip) as tip, rtrim(d.Contract) as numar, convert(varchar(10),d.data,101) as data, 
	rtrim(d.Explicatii) as explicatii, convert(varchar(10),d.termen,101) as termen, 
	isnull(rtrim(left(gPred.denumire_gestiune,30)),'') as dengestiune, rtrim(d.gestiune) as gestiune,  
	rtrim(isnull(t.denumire,'')) as dentert, rtrim(d.factura) as factura, 
	rtrim(d.Tert) as tert, rtrim(contract_coresp) as contractcor, rtrim(d.Punct_livrare) as punctlivrare,rtrim(inft.Descriere) as denpunctlivrare, 
	isnull(rtrim(lm.denumire),'') as denlm, rtrim(d.loc_de_munca) as lm,
	isnull(rtrim(left(gPrim.denumire_gestiune,30)),'') as dengestprim, rtrim(d.Cod_dobanda) as gestprim, 
	rtrim(d.valuta) as valuta, convert(decimal(13,4),d.curs) as curs, 
	--convert(decimal(15,2),d.total_contractat) as valoare,
	--convert(decimal(15,2),d.total_tva) as valtva,  
	--convert(decimal(15,2),d.total_contractat+d.total_tva) as valtotala, 
	convert(decimal(15,2),(select sum(cantitate*pret) from pozcon p where p.subunitate=d.subunitate and p.tip=d.tip and p.contract=d.contract and p.data=d.data)/*d.total_contractat*/) as valoare, 
	convert(decimal(15,2),(select sum(cantitate*pret*cota_tva/100) from pozcon p where p.subunitate=d.subunitate and p.tip=d.tip and p.contract=d.contract and p.data=d.data)/*d.total_contractat+d.total_tva*/) as valtva, 
	convert(decimal(15,2),(select sum(cantitate*pret*(1+cota_tva/100)) from pozcon p where p.subunitate=d.subunitate and p.tip=d.tip and p.contract=d.contract and p.data=d.data)/*d.total_contractat+d.total_tva*/) as valtotala, 
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
	convert(varchar(10),(select max(p.Data_operarii) from pozcon p where p.subunitate = d.subunitate and p.Tip = d.Tip and p.Contract = d.Contract and p.Data = d.Data),101) as operat,
	--(case	when @period_antet='0' then (case when left(d.mod_plata,1)='1' then '1' else '0' end) 
	--		else (case when d.mod_plata='1' then 'Trimestrial' when d.mod_plata='2' then 'Semestrial'when d.mod_plata='3' then 'Anual' end) 
	--end) as comspec, 
	rtrim(d.stare) as stare, 
	convert(int,d.Dobanda) as categpret,
	isnull(rtrim(cp.Denumire),'')+' ('+LTRIM(str(d.Dobanda))+')' as dencategpret,
	--(case when @areDetalii=1 then '' else null end) as detalii, 
	--( case when @aredetalii='' then  d.detalii else '' end) as detalii,
	d.stare + '-' + (case when isnull(pa.val_alfanumerica, '')<>'' then pa.val_alfanumerica else (case d.Stare when '0' then 'Operat' when '1' then 'Definitiv' when '2' then 'Blocat' when '3' then 'Confirmat' when '4' then 'Expediat' when '5' then 'In vama' when '6' then 'Realizat' when '7' then 'Reziliat' else d.stare end) end) as denstare, 
	RTrim(d.Mod_penalizare) as info1, convert(decimal(15,2),d.Val_reziduala) as info2, d.Sold_initial as info3, d.Procent_penalizare as info4, 
	(case when d.Tip not in ('BF', 'FA') then convert(decimal(15,2),d.discount) else 0 end) as info5, 
	--RTRIM(case when d.Tip not in ('BF', 'FA') then d.Responsabil else '' end) as info6,
	rtrim(isnull(d.responsabil,'')) as info6,
	(case d.Stare when '0' then '#000000' when '1' then '#0000FF' when '4' then '#408080' else '#808080' end) as culoare, 
	(case d.Stare when '0' then 0 else 1 end) as _nemodificabil
into #wcon
from con d 
	left join (select REPLACE(rtrim(Parametru),'STAREBK','') as stare, rtrim(Val_alfanumerica) val_alfanumerica 
					from par where tip_parametru='UC' and parametru like 'STAREBK%') pa on pa.stare=d.stare
	left outer join terti t on t.subunitate = d.subunitate and t.tert = d.tert 
	LEFT join infotert inft on inft.subunitate=t.subunitate and inft.tert=t.tert and d.Punct_livrare=inft.Identificator
	left outer join gestiuni gPred on gPred.subunitate = d.subunitate and gPred.cod_gestiune = d.gestiune 
	left outer join gestiuni gPrim on gPrim.subunitate = d.subunitate and gPrim.cod_gestiune = d.Cod_dobanda 
	left outer join categpret cp on d.Tip='BK' and cp.Categorie = d.Dobanda 
	left outer join lm on lm.cod = d.loc_de_munca 
	left outer join extcon ext on ext.subunitate=d.subunitate and ext.Tip=d.Tip and ext.contract=d.contract and ext.Data=d.Data and ext.tert=d.tert and ext.Numar_pozitie=1
	left outer join (select valoare from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE') gu on gu.valoare=d.gestiune
	left outer join (select valoare from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTBK') gpu on d.Tip in ('BF', 'BK', 'BP') and gpu.valoare=d.Cod_dobanda 
	--left outer join proprietati cu on cu.valoare=d.tert and cu.tip='UTILIZATOR' and cu.cod=@userASiS and cu.cod_proprietate='CLIENT'
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and d.Loc_de_munca=lu.cod
where d.subunitate=@subunitate 
	and d.tip = @tip
	and (@data is null or d.Data=@data)
	and (@numar='' or d.contract=@numar )
	and (@fNumar='' or d.contract like @fNumar+'%' )
	and (@fAn='' or year(d.Data) like @fAn+'%')--sa tina cont de filtru pe an 
	and d.data between @dataJos and @dataSus
	and (@fGestiune='' or d.gestiune like @fGestiune + '%' )
	and (@fDenGestiune='' or left(isnull(gPred.denumire_gestiune, ''), 30) like '%' + @fDenGestiune + '%')
	and (@fGestPrim='' or d.Cod_dobanda like @fGestPrim + '%' )
	and (@fDenGestPrim='' or left(isnull(gPrim.denumire_gestiune, ''), 30) like '%' + @fDenGestPrim + '%')
	and (@fTert='' or d.tert like @fTert + '%')
	and (@fDenTert='' or isnull(t.denumire, '') like '%' + @fDenTert + '%')
	and (@fLm='' or d.loc_de_munca like @fLm + '%')
	and (@fDenLm='' or isnull(lm.denumire, '') like '%' + @fDenLm + '%')
	and (isnull(rtrim(pa.val_alfanumerica),'') like '%' + @fStare + '%' or rtrim(d.stare) like '%' + @fStare + '%')
	and d.total_contractat between @fValoareJos and @fValoareSus
	and ((d.tip<>'BK' or @lista_gestiuni=0 or gu.valoare is not null or d.Gestiune='') 
		or (d.tip='BK' 
			and (@lista_gestiuni=0 or (gu.valoare is not null and @lista_gbk=0) or d.Gestiune='' -- daca Gestiunea este in lista proprie de GESTIUNE si nu are GESTBK
			or gpu.Valoare is not null and d.Cod_dobanda<>''))) -- sau daca Gestiunea primitoare este GESTBK
	and (d.tip not in ('BK', 'BP') or @lista_clienti=0 or exists (select * from @clienti c where c.tert=d.tert ))
	and (@filtruLocMuncaUtilizator=0 or lu.cod is not null) --or d.tip='BK' and gu.Valoare is not null)
	and (@fInfo6='' or d.responsabil like '%'+@fInfo6+'%' )
	and (@fContractCor='' or d.contract_coresp like @fContractCor+'%')
	and (@fComSpec is null or (case when left(d.mod_plata,1)='1' then '1' else '0' end)=@fComSpec)
order by operat desc, d.data desc, d.Contract desc 

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
order by convert(datetime,data,101) desc, numar desc 
for xml raw

end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+'(wIaCon)'
end catch

if ISNULL(@msgEroare,'')!=''
	raiserror(@msgEroare, 11, 1)
/*select * from infotert*/