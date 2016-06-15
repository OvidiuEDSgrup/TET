--***
create procedure [dbo].[wRUIaPosturi] @sesiune varchar(50), @parXML XML
as
declare @utilizator char(10), @userASiS varchar(20)
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

---------
select top 100 ID_post,RTRIM(scop)as scop,RTRIM(Studii)as studii,RTRIM(Experienta_necesara) as experienta_necesara,rtrim(Descriere) as descriere
	from RU_posturi 
for xml raw
