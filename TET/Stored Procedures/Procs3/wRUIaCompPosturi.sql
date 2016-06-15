--***
create procedure [dbo].[wRUIaCompPosturi] @sesiune varchar(50), @parXML XML
as
declare @utilizator char(10), @userASiS varchar(20),@id_post int
select 
	@id_post=ISNULL(@parXML.value('(/row/@ID_post)[1]','int'),0)
	
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

---------
select top 100 c.ID_comp_posturi,c.ID_comp,c.ID_post,convert(decimal(12,2),c.Pondere)as pondere,rtrim(co.Descriere) as comp_descriere,rtrim(co.Proprietati) as comp_proprietati,
		cc.ID_categ_comp,rtrim(cc.Denumire) as categ_denumire
	from RU_competente_posturi c
		inner join RU_competente co on c.ID_comp=co.ID_comp
		inner join RU_categ_comp cc on cc.ID_categ_comp=c.ID_categ_comp
where c.ID_post=@id_post			
for xml raw
