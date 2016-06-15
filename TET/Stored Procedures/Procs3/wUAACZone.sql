create PROCEDURE [dbo].[wUAACZone]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER  
AS  
declare @searchText varchar(100),@centru varchar(8),@utilizator char(10), @userASiS varchar(20)  
select @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'),  
    @centru=ISNULL(@parXML.value('(/row/@centru)[1]', 'varchar(8)'), '')  
    
---------
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------
  
select top 100 rtrim(z.zona) as cod,rtrim(z.denumire_zona) as denumire  
from zone z  
    left outer join Centre c on c.Centru=z.Centru 
    left outer join LMFiltrare lu on lu.utilizator=@utilizator and c.loc_de_munca=lu.cod
where (zona like '%'+@searchText+'%' or denumire_zona like '%'+@searchText+'%')  
  and (z.Centru=@centru or @centru='')
  and (@lista_lm=0 or lu.cod is not null)
order by rtrim(denumire_zona)  
for xml raw
--select * from zone
