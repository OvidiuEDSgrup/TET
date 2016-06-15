--***
/****** Object:  StoredProcedure [dbo].[wRUIaFunctii]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wRUIaFunctii]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare @utilizator char(10), @userASiS varchar(20)

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

---------

select	top 100 rtrim(ID_functie) as id_functie,rtrim(denumire) as denumire,rtrim(descriere) as descriere,
		rtrim(studii) as studii 
		
from ru_functii
for xml raw
