--***
create procedure [dbo].[wRUIaDomeniiCompetente] @sesiune varchar(50), @parXML XML
as
declare @utilizator char(10), @userASiS varchar(20)
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

---------
select top 100 rtrim(id_domeniu_comp) as ID_domeniu_comp ,rtrim(Denumire) as denumire, rtrim(Descriere) as descriere
	from RU_domenii_competente 
for xml raw
