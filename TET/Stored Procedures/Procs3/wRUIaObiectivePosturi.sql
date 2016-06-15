--***
create procedure [dbo].[wRUIaObiectivePosturi] @sesiune varchar(50), @parXML XML
as
declare @utilizator char(10), @userASiS varchar(20),@id_post int
select 
	@id_post=ISNULL(@parXML.value('(/row/@ID_post)[1]','int'),0)
	
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

---------
select top 100 c.ID_ob_posturi,c.ID_obiectiv,c.ID_post,convert(decimal(12,2),c.Pondere)as pondere,rtrim(co.Descriere) as ob_descriere,
	rtrim(co.Categorie) as ob_categorie,
	rtrim(co.Actiuni_realizare) as ob_actiuni_realizate
	from RU_obiective_posturi c
		inner join RU_obiective co on c.ID_obiectiv=co.ID_obiectiv
where c.ID_post=@id_post			
for xml raw
