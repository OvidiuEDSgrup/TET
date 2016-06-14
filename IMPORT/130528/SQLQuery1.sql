create procedure yso_xScriuPozcon  @fisier nvarchar(4000) as  
begin try -- scriu pozcon  
 --declare @fisier nvarchar(4000) set @fisier='\\10.0.0.10\IMPORT\testimport.xlsx '  
  declare @eroareProc varchar(500),@txtSql nvarchar(max),@sursa varchar(max),@txtSelect varchar(max)  
  ,@txtParam nvarchar(max),@eroareXL varchar(500), @contor int, @parxml xml   
   
 if OBJECT_ID('tempdb..##importXlsIniTmp') is not null  
  drop table ##importXlsIniTmp  
  
 set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=1;HDR=YES;";'  
 set @sursa=REPLACE(@sursa,'@fisier',@fisier)  
 set @txtSelect='Select * from [pozcon$]'  
 set @txtSql=  
 'select * into ##importXlsIniTmp  
 from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''  
 ,@sursa  
 , @txtSelect) x '  
 set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')  
 set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')  
 exec sp_executesql @txtSql  
    
 if OBJECT_ID('tempdb..#importXlsTmp') is not null  
  drop table #importXlsTmp  
  
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
 into #importXlsTmp  
 from ##importXlsIniTmp where _linieimport is not null --and isnull(discount2,0)>0  
 order by _linieimport  
  
 if OBJECT_ID('tempdb..#importXlsDifTmp') is not null  
  drop table #importXlsDifTmp  
  
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
 into #importXlsDifTmp  
 from #importXlsTmp   
 except  
 select   tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta--, termene  
 , pret, discount, discount2, discount3, cotatva, punctlivrare, modplata  
 --, cant_aprobata  
 , explicatii--, numarpozitie  
 , atp--, dataexpirarii, obiect, denobiect  
 from yso_vIaPozcon where tip='BF'  
  
 alter table #importXlsDifTmp add nrcrt int identity(1,1) not null  
 create unique clustered index id on #importXlsDifTmp (nrcrt)  
 --create nonclustered index preturi on #preturiXlsDifTmp (cod, catpret, tippret, data_inferioara, pret_vanzare, pret_cu_amanuntul)  
  
/*   
select * from #importXlsTmp   
select tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta  
 , pret  
 , discount, discount2, discount3, cotatva, punctlivrare, modplata  
 , explicatii  
 , atp  
 ,(select TOP 1 1 from pozcon v   
       where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data)  
from #importXlsDifTmp t  
where numar='RO22547417EU  '  
select * from pozcon v   
       where v.Tip='bf' and v.Contract='RO22547417EU  '   
       and v.Tert='RO22547418'-- and v.Data=t.data  
  
select tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta, pret  
 , discount, discount2, discount3, cotatva, punctlivrare, modplata, explicatii  
 , atp  
from yso_vIaPozcon where numar='RO22547417EU  '  
  
*/  
 declare @randuri int  
 select @randuri=MAX(nrcrt) from #importXlsDifTmp  
  
 if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null  
  drop table #mesajeASiSTmp  
    
 select top 0 Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj   
 into #mesajeASiSTmp from mesajeASiS  
   
 if OBJECT_ID('tempdb..#importXlsErrTmp') is not null  
  drop table #importXlsErrTmp  
    
 select top 0 _linieimport, convert(varchar(500),'') as _eroareimport into #importXlsErrTmp from #importXlsTmp t   
  
 set @contor=1  
 while @contor<=@randuri  
 begin  
  begin try  
   set @parxml=(select tip, subtip, numar, data, tert, lm=i.Loc_munca, scadenta=i.Discount,  
     (select tip, subtip, numar, data, tert, cod, gestiune, cantitate, valuta  
      , pret=ISNULL(nullif(pret,0),1)  
      , discount  
      , info1=discount2, info3=discount3, cotatva, punctlivrare, modplata, explicatii  
      , atp  
      , Tpret=1  
      ,isnull((select TOP 1 1 from pozcon v   
       where v.Tip=t.tip and v.Contract=t.numar and v.Tert=t.tert and v.Data=t.data   
        and v.cod=t.cod),0) as [update]   
      from #importXlsDifTmp t   
      where t.nrcrt=tt.nrcrt for xml raw,type)  
    from #importXlsDifTmp tt left join infotert i on i.Subunitate='1' and i.Tert=tt.tert and i.Identificator=''  
     where tt.nrcrt=@contor for xml raw)  
   --if '0007001A'=@parXML.value('(/row/@cod)[1]','varchar(20)')  
   -- print 'stop'  
   if @parxml is not null  
     exec wScriuPozcon @sesiune=null,@parxml=@parxml  
   end try  
   begin catch  
   set @eroareProc = ERROR_MESSAGE()  
   begin try  
    insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)  
    select '','','S',HOST_ID(),'Erori import linie pozcon',@eroareProc  
      
    insert #importXlsErrTmp  
    select _linieimport, @eroareProc as _eroareimport from #importXlsTmp t inner join #importXlsDifTmp d  
     on d.tip=t.tip and d.subtip=t.subtip and d.numar=t.numar and d.data=t.data and d.tert=t.tert and d.cod=t.cod   
      and d.gestiune=t.gestiune and d.cantitate=t.cantitate and d.valuta=t.valuta   
      and d.pret=t.pret and d.discount=t.discount and d.discount2=t.discount2   
      and d.discount3=t.discount3 and d.cotatva=t.cotatva and d.punctlivrare=t.punctlivrare and d.modplata=t.modplata   
      and d.explicatii=t.explicatii   
      and d.atp=t.atp   
    where d.nrcrt=@contor  
   end try  
   begin catch  
    set @eroareXL = ERROR_MESSAGE()  
    insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)  
    select '','','S',HOST_ID(),'Erori raportare erori in tabel',@eroareXL  
   end catch  
   end catch  
    
   set @contor=@contor+1  
 end  
 begin try  
  set @sursa='Excel 12.0;Database=@fisier;Extended Properties="Excel 12.0 Xml;IMEX=0;HDR=YES;";'  
  set @sursa=REPLACE(@sursa,'@fisier',@fisier)  
  set @txtSelect='Select * from [pozcon$]'  
  set @txtSql=  
  'UPDATE x   
  SET _eroareimport = @eroareimport  
  from OPENROWSET(''Microsoft.ACE.OLEDB.12.0''  
  ,@sursa  
  , @txtSelect) x '  
  set @txtSql=REPLACE(@txtSql,'@sursa',''''+@sursa+'''')  
  set @txtSql=REPLACE(@txtSql,'@txtSelect',''''+@txtSelect+'''')  
  set @txtParam='@eroareimport varchar(500)'  
  exec sp_executesql @txtSql, @txtParam, ''  
  set @txtSql=REPLACE(@txtSql,'@eroareimport','e._eroareimport')  
  set @txtSql=@txtSql+' inner join #importXlsErrTmp e on e._linieimport=x._linieimport'  
  exec sp_executesql @txtSql  
 end try  
 begin catch  
  set @eroareXL = ERROR_MESSAGE()  
  insert #mesajeASiSTmp (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj)  
  select '','','S',HOST_ID(),'Erori raportare erori in excel',@eroareXL  
 end catch  
   
 insert mesajeASiS (Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj, Data, Ora, Stare)  
 select t.*,GETDATE(),'','' from   
  (select Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect  
   , convert(varchar,count(*))+':'+Mesaj as Mesaj from #mesajeASiSTmp  
  group by Tip_expeditor, Expeditor, Tip_destinatar, Destinatar, Subiect, Mesaj) t  
   
 if OBJECT_ID('tempdb..##importXlsIniTmp') is not null  
  drop table ##importXlsIniTmp   
  
 if OBJECT_ID('tempdb..#importXlsTmp') is not null  
  drop table #importXlsTmp  
   
   
 if OBJECT_ID('tempdb..#importXlsDifTmp') is not null  
  drop table #importXlsDifTmp  
    
 if OBJECT_ID('tempdb..#mesajeASiSTmp') is not null  
  drop table #mesajeASiSTmp -- select * from #mesajeASiSTmp  
    
 if OBJECT_ID('tempdb..#importXlsErrTmp') is not null  
  drop table #importXlsErrTmp -- select * into testerrxls from #importXlsErrTmp  
   
end try  
begin catch  
 declare @mesaj varchar(254)  
 set @mesaj = 'yso_xScriuPozcon: '+ ERROR_MESSAGE()   
 raiserror(@mesaj, 11, 1)   
end catch  