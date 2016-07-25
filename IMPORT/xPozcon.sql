--/*
DROP VIEW yso_vIaPozcon
GO
create view yso_vIaPozcon as
select	
		--rtrim(p.subunitate) as subunitate
		rtrim(p.tip) as tip
		, rtrim(p.tip) as subtip
		, CASE p.Tip WHEN 'BF' THEN 'Contract beneficiar' WHEN 'BK' THEN 'Comanda livrare' 
			WHEN 'FA' THEN 'Contract furnizor' WHEN 'FC' THEN 'Comanda aprovizionare' ELSE '' END AS dentip
		, rtrim(p.contract) as numar
		,convert(varchar(10),p.data,101) as data
		,rtrim(p.tert) as tert,
		isnull(rtrim(t.denumire), '') as dentert --/*sp
		, rtrim(contract_coresp) as contractcor--,rtrim(d.Punct_livrare) as punctlivrare,rtrim(inft.Descriere) as denpunctlivrare
		, isnull(rtrim(lm.denumire),'') as denlm, rtrim(d.loc_de_munca) as lm 
		, rtrim(isnull(d.Scadenta,'')) as scadenta--sp*/
		, rtrim(p.cod ) as cod, 
		rtrim(p.cod)+' - '+ rtrim(coalesce(n.denumire,g.denumire, '')) as dencod,  
		rtrim(coalesce(n.denumire,g.denumire, '')) as denumire,    
		rtrim(p.factura) as gestiune
		,isnull(rtrim(left(gest.denumire_gestiune, 30)), '') as dengestiune 
		,  convert(decimal(17, 5), p.cantitate) as cantitate
		,  rtrim(isnull(p.valuta, '')) as valuta,  
		convert(varchar(10),p.termen,101) as termene
		, convert(decimal(14, 4), p.pret) as Tpret
		, convert(decimal(17, 5), p.cantitate) as Tcantitate
		, convert(decimal(17, 5), p.cant_realizata) as Tcant_realizata,  
		rtrim(isnull(n.um, '')) as um1, convert(decimal(17, 5), p.cantitate-(case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum1,    
		RTRIM(isnull(n.UM_1, '')) as um2, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_1, 0)) as coefconvum2,     
		convert(decimal(17, 5), (case when isnull(n.UM_1, '')<>'' and isnull(n.Coeficient_conversie_1, 0)<>0 then floor((p.cantitate-(case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end))/n.Coeficient_conversie_1) else 0 end)) as cantitateum2,    
		RTRIM(isnull(n.UM_2, '')) as um3, CONVERT(decimal(10,5), isnull(n.coeficient_conversie_2, 0)) as coefconvum3,     
		convert(decimal(17, 5), (case when isnull(n.UM_2, '')<>'' and isnull(n.Coeficient_conversie_2, 0)<>0 then floor(p.Cantitate/n.Coeficient_conversie_2) else 0 end)) as cantitateum3,     
		convert(decimal(17, 5), p.pret) as pret, convert(decimal(10, 4), p.pret_promotional) as cant_transferata,     
		convert(decimal(12, 5), p.discount) as discount, 
		convert(decimal(12, 5), isnull(pe.pret, 0)) as info1,
		convert(decimal(12, 5), isnull(pe.cantitate, 0)) as info3,
		convert(decimal(5, 2), p.cota_tva) as cotatva,     
		rtrim(p.punct_livrare) as punctlivrare, rtrim(d.Mod_plata) as modplata,  --/*sp
		CASE d.Mod_plata WHEN '0' THEN 'OP' WHEN '1' THEN 'CEC' 
			WHEN '2' THEN 'Numerar' ELSE '' END AS denmodplata,
		--sp*/'('+rtrim(p.mod_de_plata)+')'+rtrim(s.denumire) as denmodplata,           
		isnull(rtrim(gest.tip_gestiune), '') as tipgestiune,         
		convert(decimal(17, 5),p.cant_realizata) as cant_realizata,       
		convert(decimal(17, 5),p.cant_aprobata) as cant_aprobata, convert(varchar(10),p.termen,101) as termen_poz,       
		rtrim(p.Explicatii) as explicatii, p.numar_pozitie as numarpozitie, RTrim(ISNULL(pe.Explicatii, '')) as atp,    
		convert(char(10), isnull(pe.termen, '01/01/1901'), 101) as dataexpirarii,       
		rtrim(isnull(dp.Obiect, '')) as obiect, 
		rtrim(isnull(obiecteds.denumire, '')) as denobiect
		, rtrim(isnull(pe.punct_livrare, '')) as info2       
		,rtrim(isnull(pe2.explicatii, '')) as info4,    rtrim(isnull(pe2.punct_livrare, '')) as info5,      
		convert(char(10), isnull(dp.data1, '01/01/1901')) as info6, convert(char(10), isnull(dp.data2, '01/01/1901')) as info7,       
		convert(decimal(17, 5), isnull(dp.val1, 0)) as info8,  convert(decimal(17, 5), isnull(dp.val2, 0)) as info9,       
		convert(decimal(17, 5), isnull(dp1.val1, 0)) as info10,   convert(decimal(17, 5), isnull(dp1.val2, 0)) as info11,       
		rtrim(isnull(dp.observatii, '')) as info12,  rtrim(isnull(dp.info1, '')) as info13, rtrim(isnull(dp.info2, '')) as info14,       
		rtrim(isnull(dp1.observatii, '')) as info15,  rtrim(isnull(dp1.info1, '')) as info16,    
		rtrim(isnull(dp1.info2, '')) as info17,   
		convert(decimal(15,2),(p.cant_realizata)*p.pret) as Tfacturat 
from pozcon p --/*sp
left outer join con d on d.Subunitate=p.Subunitate and d.Tip=p.Tip and d.Contract=p.Contract and d.Tert=p.Tert and d.Data=p.Data 
left outer join lm on lm.cod = d.loc_de_munca --sp*/
left outer join nomencl n on (p.tip not in ('BF','FA') or p.Mod_de_plata='') and n.cod = p.Cod       
left outer join grupe g on p.Mod_de_plata='G' and g.Grupa=p.cod
left outer join surse s on s.Cod=p.Mod_de_plata      
left outer join terti t on t.subunitate = p.subunitate and t.tert = p.Tert      
left outer join gestiuni gest on gest.cod_gestiune = p.factura      
left outer join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=p.Tip and pe.Contract=p.Contract and pe.Tert=p.Tert and pe.Data=p.Data and pe.Cod=p.Cod      
left outer join pozcon pe2 on pe2.Subunitate='EXPAND2' and pe2.Tip=p.Tip and pe2.Contract=p.Contract and pe2.Tert=p.Tert and pe2.Data=p.Data and pe2.Cod=p.Cod      
left outer join detpozcon dp on dp.subunitate=p.subunitate and dp.tip=p.tip and dp.contract=p.contract and dp.tert=p.tert and dp.data=p.data and dp.numar_pozitie=p.numar_pozitie and dp.numar_ordine=0      
left outer join obiecteds on obiecteds.cod_obiect=dp.obiect      
left outer join detpozcon dp1 on dp1.subunitate=p.subunitate and dp1.tip=p.tip and dp1.contract=p.contract and dp1.tert=p.tert and dp1.data=p.data and dp1.numar_pozitie=p.numar_pozitie and dp1.numar_ordine=1           
where p.Subunitate='1' 
--order by p.Subunitate, p.Tip, p.Contract, p.Data, p.Tert, p.Cod, p.Numar_pozitie desc
go

drop procedure yso_xIaPozcon 
go
create procedure yso_xIaPozcon @tip char(2)=null as
select * from yso_vIaPozcon v
where ISNULL(@tip,'')='' or v.tip=@tip
go
--*/
/*
if exists (select * from sysobjects where name ='yso_xImportPozcon')
drop procedure yso_xImportPozcon
go
create procedure yso_xImportPozcon as --@tabela varchar(255), @fisier nvarchar(4000) as
begin try -- scriu pozcon
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
	from yso_vIaPozcon where tip='BF'
end try
begin catch
end catch
go
--*/
if exists (select * from sysobjects where name ='yso_xScriuPozcon')
drop procedure yso_xScriuPozcon
go
create procedure yso_xScriuPozcon @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as

declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)

begin try
	set @parxml=(select fara_luare_date=1 ,*
			,(select *
				,isnull((select TOP 1 1 from pozcon v 
					where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data 
						and v.cod=t.cod),0) as [update] 
				from ##importXlsDifTmp t 
				where t._nrdif=tt._nrdif for xml raw,type)
		from ##importXlsDifTmp tt 
			where tt._nrdif=@_nrdif for xml raw)
	if @parxml is not null
		exec wScriuPozcon @sesiune=null,@parxml=@parxml
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp d
		on d.tip=t.tip and d.subtip=t.subtip and d.numar=t.numar and d.data=t.data and d.tert=t.tert and d.cod=t.cod and d.pret=t.pret 
	where d._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
GO
if exists (select * from sysobjects where name ='yso_xStergPozcon')
drop procedure yso_xStergPozcon
go
create procedure yso_xStergPozcon @_nrdif int as --@tabela varchar(255), @fisier nvarchar(4000) as

declare @txtSql nvarchar(max),@txtSelect varchar(max),@txtParam nvarchar(max), @parxml xml
	,@eroareProc varchar(500)

begin try
/*
	set @parxml=(select fara_luare_date=1
					,tip, subtip, numar, data, tert,
			(select *
				,isnull((select TOP 1 1 from pozcon v 
					where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data 
						and v.cod=t.cod),0) as [update] 
				from ##importXlsDifTmp t 
				where t._nrdif=tt._nrdif for xml raw,type)
		from ##importXlsDifTmp tt 
			where tt._nrdif=@_nrdif for xml raw)
	if @parxml is not null
		exec wScriuPozcon @sesiune=null,@parxml=@parxml
*/
	delete v
	from pozcon v 
		inner join ##importXlsDifTmp t
			on v.Tip=t.tip and v.Contract=t.numar --and v.cod=t.cod --and v.Tert=t.tert and v.Data=t.data 
	where t._nrdif=@_nrdif 
	
	delete v
	from con v 
		inner join ##importXlsDifTmp t
			on v.Tip=t.tip and v.Contract=t.numar --and v.Tert=t.tert and v.Data=t.data 
		outer apply (select top 1 cod from pozcon p 
			where  v.Tip=p.tip and v.Contract=p.Contract /*and v.Tert=p.tert and v.Data=p.data*/) p
	where t._nrdif=@_nrdif 
		and p.Cod is null
end try
begin catch
	set @eroareProc = ERROR_MESSAGE()
	insert ##importXlsErrTmp
	select _linieimport, @eroareProc as _eroareimport from ##importXlsTmp t inner join ##importXlsDifTmp d
		on d.tip=t.tip and d.subtip=t.subtip and d.numar=t.numar and d.data=t.data and d.tert=t.tert and d.cod=t.cod and d.pret=t.pret 
	where d._nrdif=@_nrdif
	raiserror(@eroareProc, 11, 1)
end catch
GO