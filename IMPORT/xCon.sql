--/*
DROP VIEW yso_vIaCon
GO
create view yso_vIaCon as
select top 100 
	rtrim(d.subunitate) as subunitate, rtrim(d.tip) as tip
	,CASE d.Tip WHEN 'BF' THEN 'Contract beneficiar' WHEN 'BK' THEN 'Comanda livrare' 
			WHEN 'FA' THEN 'Contract furnizor' WHEN 'FC' THEN 'Comanda aprovizionare' ELSE '' END AS dentip
	,rtrim(d.Contract) as numar, convert(varchar(10),d.data,101) as data, 
	rtrim(d.Explicatii) as explicatii, convert(varchar(10),d.termen,101) as termen, 
	isnull(rtrim(left(gPred.denumire_gestiune,30)),'') as dengestiune, rtrim(d.gestiune) as gestiune,  
	rtrim(isnull(t.denumire,'')) as dentert, rtrim(d.factura) as factura, 
	rtrim(d.Tert) as tert, rtrim(contract_coresp) as contractcor, rtrim(d.Punct_livrare) as punctlivrare,rtrim(inft.Descriere) as denpunctlivrare, 
	isnull(rtrim(lm.denumire),'') as denlm, rtrim(d.loc_de_munca) as lm,
	isnull(rtrim(left(gPrim.denumire_gestiune,30)),'') as dengestprim, rtrim(d.Cod_dobanda) as gestprim, 
	rtrim(d.valuta) as valuta, convert(decimal(13,4),d.curs) as curs, 
	convert(decimal(15,2),d.total_contractat) as valoare,
	convert(decimal(15,2),d.total_tva) as valtva,  
	convert(decimal(15,2),d.total_contractat+d.total_tva) as valtotala, 
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
	--left outer join (select valoare from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTIUNE') gu on gu.valoare=d.gestiune
	--left outer join (select valoare from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='GESTBK') gpu on d.Tip in ('BF', 'BK', 'BP') and gpu.valoare=d.Cod_dobanda 
	--left outer join proprietati cu on cu.valoare=d.tert and cu.tip='UTILIZATOR' and cu.cod=@userASiS and cu.cod_proprietate='CLIENT'
	--left outer join LMFiltrare lu on lu.utilizator=@userASiS and d.Loc_de_munca=lu.cod
where d.Subunitate='1' --and p.tip='BF'
--order by p.Subunitate, p.Tip, p.Contract, p.Data, p.Tert, p.Cod, p.Numar_pozitie desc
go

drop procedure yso_xIaCon 
go
create procedure yso_xIaCon @tip char(2)=null as
select * from yso_vIaCon v
where ISNULL(@tip,'')='' or v.tip=@tip
go
--*/
/*
if exists (select * from sysobjects where name ='yso_xImportCon')
drop procedure yso_xImportCon
go
create procedure yso_xImportCon as --@tabela varchar(255), @fisier nvarchar(4000) as
begin try -- scriu Con
	--declare @tabela='tehn', @fisier nvarchar(4000)='\\10.0.0.10\IMPORT\testimport.xlsx '
	select 
	tip=isnull(tip,''), subtip=isnull(subtip,''), dentip=isnull(dentip,''), numar=isnull(numar,''), data=isnull(data,'')
	, tert=isnull(tert,''), dentert=isnull(dentert,''), cod=isnull(cod,''), dencod=isnull(dencod,'')
	, denumire=isnull(denumire,''), gestiune=isnull(gestiune,''), dengestiune=isnull(dengestiune,'')
	, cantitate=isnull(cantitate,''), valuta=isnull(valuta,''), termene=isnull(termene,'')
	, Tpret=isnull(Tpret,''), Tcantitate=isnull(Tcantitate,''), Tcant_realizata=isnull(Tcant_realizata,'')
	, um1=isnull(um1,''), cantitateum1=isnull(cantitateum1,''), um2=isnull(um2,''), coefconvum2=isnull(coefconvum2,'')
	, cantitateum2=isnull(cantitateum2,''), um3=isnull(um3,''), coefconvum3=isnull(coefconvum3,'')
	, cantitateum3=isnull(cantitateum3,''), pret=isnull(pret,''), cant_transferata=isnull(cant_transferata,'')
	, discount=isnull(discount,''), discount2=isnull(discount2,''), discount3=isnull(discount3,'')
	, cotatva=isnull(cotatva,''), punctlivrare=isnull(punctlivrare,''), modplata=isnull(modplata,'')
	, denmodplata=isnull(denmodplata,''), tipgestiune=isnull(tipgestiune,''), cant_realizata=isnull(cant_realizata,'')
	, cant_aprobata=isnull(cant_aprobata,''), termen_poz=isnull(termen_poz,''), explicatii=isnull(explicatii,'')
	, numarpozitie=isnull(numarpozitie,''), atp=isnull(atp,''), dataexpirarii=isnull(dataexpirarii,'')
	, obiect=isnull(obiect,''), denobiect=isnull(denobiect,''), info2=isnull(info2,''), info4=isnull(info4,'')
	, info5=isnull(info5,''), info6=isnull(info6,''), info7=isnull(info7,''), info8=isnull(info8,''), info9=isnull(info9,'')
	, info10=isnull(info10,''), info11=isnull(info11,''), info12=isnull(info12,''), info13=isnull(info13,'')
	, info14=isnull(info14,''), info15=isnull(info15,''), info16=isnull(info16,''), info17=isnull(info17,'')
	, Tfacturat=isnull(Tfacturat,'')
	,_linieimport
	into ##importXlsTmp
	from ##importXlsIniTmp where _linieimport is not null --and isnull(discount2,0)>0
	order by _linieimport
	
	select distinct tip, subtip, numar, data, tert, cod, gestiune
	, cantitate=convert(decimal(17,5),cantitate)
	, valuta--, termene
	, pret=convert(decimal(17,5),pret)
	, discount=convert(decimal(12,5),discount)
	, discount2=convert(decimal(12,5),discount2)
	, discount3=convert(decimal(12,5),discount3)
	, cotatva=convert(decimal(5,2),cotatva)
	, punctlivrare, modplata
	--, cant_aprobata=convert(decimal(17,5),cant_aprobata)
	, explicatii
	--, numarpozitie=convert(int,numarpozitie)
	, atp--, dataexpirarii, obiect, denobiect
	into ##importXlsDifTmp
	from ##importXlsTmp 
	except
	select			tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta--, termene
	, pret, discount, discount2, discount3, cotatva, punctlivrare, modplata
	--, cant_aprobata
	, explicatii--, numarpozitie
	, atp--, dataexpirarii, obiect, denobiect
	from yso_vIaCon where tip='BF'
end try
begin catch
end catch
go
--*/
if exists (select * from sysobjects where name ='yso_xScriuCon')
drop procedure yso_xScriuCon
go
create procedure yso_xScriuCon @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as

declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)

begin try
	set @parxml=(select fara_luare_date=1
					,tip, subtip, numar, data, tert,
			(select *
				,isnull((select TOP 1 1 from Con v 
					where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data),0) as [update] 
				from ##importXlsDifTmp t 
				where t._nrdif=tt._nrdif for xml raw,type)
		from ##importXlsDifTmp tt 
			where tt._nrdif=@_nrdif for xml raw)
	if @parxml is not null
		exec wScriuCon @sesiune=null,@parxml=@parxml
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp d
		on d.tip=t.tip and d.subtip=t.subtip and d.numar=t.numar and d.data=t.data and d.tert=t.tert 
	where d._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
GO
if exists (select * from sysobjects where name ='yso_xStergCon')
drop procedure yso_xStergCon
go
create procedure yso_xStergCon @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as

declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)

begin try
/*
	set @parxml=(select fara_luare_date=1
					,tip, subtip, numar, data, tert,
			(select *
				,isnull((select TOP 1 1 from Con v 
					where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data 
						and v.cod=t.cod),0) as [update] 
				from ##importXlsDifTmp t 
				where t._nrdif=tt._nrdif for xml raw,type)
		from ##importXlsDifTmp tt 
			where tt._nrdif=@_nrdif for xml raw)
	if @parxml is not null
		exec wScriuCon @sesiune=null,@parxml=@parxml
*/
	
	delete v
	from con v 
		inner join ##importXlsDifTmp t
			on v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data 
		outer apply (select top 1 cod from pozCon p 
			where  v.Tip=p.tip and v.Contract=p.Contract and v.Tert=p.tert and v.Data=p.data) p
	where t._nrdif=@_nrdif 
		and p.Cod is null
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp d
		on d.tip=t.tip and d.subtip=t.subtip and d.numar=t.numar and d.data=t.data and d.tert=t.tert 
	where d._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
GO