﻿create PROCEDURE [dbo].[wUAACGrupe]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER  
AS  
declare @searchText varchar(100),@localitate varchar(8)  ,@utilizator char(10), @userASiS varchar(20)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%') 

---------
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------
  
select top 100 rtrim(grupa) as cod,rtrim(denumire) as denumire  
from grabonat 
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and loc_de_munca=lu.cod 
where (grupa like '%'+@searchText+'%' or denumire like '%'+@searchText+'%') 
  and (@lista_lm=0 or lu.cod is not null) 
order by rtrim(denumire)
for xml raw
--select * from grabonat
