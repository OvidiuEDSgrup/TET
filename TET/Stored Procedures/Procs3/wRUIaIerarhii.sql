--***
create procedure [dbo].[wRUIaIerarhii] @sesiune varchar(50), @parXML XML
as
declare @utilizator char(10), @userASiS varchar(20)
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

---------
select top 100 ID_ierarhie,Nivel_ierarhic as nivel_ierarhic, rtrim(Descriere) as descriere
	from RU_ierarhii
for xml raw
