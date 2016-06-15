--***
create procedure [dbo].[wRUIaCatCompetente] @sesiune varchar(50), @parXML XML
as
declare @utilizator char(10), @userASiS varchar(20)
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

---------
select top 100  ID_categ_comp,rtrim(Descriere) as descriere, rtrim(Denumire) as denumire
	from RU_categ_comp
for xml raw
