--***
create procedure [dbo].[wRUIaIerarhiiPosturi] @sesiune varchar(50), @parXML XML
as
declare @utilizator char(10), @userASiS varchar(20),@id_post int
select 
	@id_post=ISNULL(@parXML.value('(/row/@ID_post)[1]','int'),0)
	
---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

---------
select top 100 c.ID_ierarhie_post,c.ID_ierarhie,c.ID_post_parinte,c.ID_post,CONVERT(varchar(10),c.data_inceput,101)as data_inceput,
	CONVERT(varchar(10),c.Data_sfarsit,101)as data_sfarsit,rtrim(cc.Descriere) as ierarhie_descriere,cc.Nivel_ierarhic as nivel_ierarhic,
	RTRIM(co.Descriere) as post_descriere	
from RU_ierarhie_post c
		left outer	 join RU_posturi co on c.ID_post_parinte=co.ID_post
		left outer join RU_ierarhii cc on c.ID_ierarhie=cc.ID_ierarhie
where c.ID_post=@id_post			
for xml raw
