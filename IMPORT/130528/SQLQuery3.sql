select _eroareimport=(isnull([_eroareimport],'')),_linieimport=(isnull([_linieimport],'')),tip=convert(varchar(2),isnull([tip],'')),subtip=convert(varchar(2),isnull([subtip],'')),numar=convert(varchar(20),isnull([numar],''))
,data=convert(varchar(10),isnull([data],''))
,tert=convert(varchar(13),isnull([tert],''),101),cod=convert(varchar(20),isnull([cod],'')),gestiune=convert(varchar(20),isnull([gestiune],'')),cantitate=convert(decimal(17,5),isnull([cantitate],'')),termene=convert(varchar(10),isnull([termene],'')),pret=convert(decimal(17,5),isnull([pret],'')),discount=convert(decimal(12,5),isnull([discount],'')),cotatva=convert(decimal(5,2),isnull([cotatva],'')),modplata=convert(varchar(8),isnull([modplata],'')),cant_aprobata=convert(decimal(17,5),isnull([cant_aprobata],'')),termen_poz=convert(varchar(10),isnull([termen_poz],'')),explicatii=convert(varchar(200),isnull([explicatii],'')),numarpozitie=convert(int,isnull([numarpozitie],''))
 --into ##importXlsTmp 
 from ##importXlsIniTmp 
 where numar='RO16689205'
 order by _linieimport
 
 select * from ##importXlsIniTmp