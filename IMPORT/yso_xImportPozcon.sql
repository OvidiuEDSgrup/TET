
--*/
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

