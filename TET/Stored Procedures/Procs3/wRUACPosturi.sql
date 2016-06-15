/****** Object:  StoredProcedure [dbo].[wRUACPosturi]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE  [dbo].[wRUACPosturi]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wRUACPosturiSP' and type='P')      
	exec wRUACPosturiSP @sesiune,@parXML      
else      
begin
declare @searchText varchar(80),@tip varchar(2),@utilizator char(10), @userASiS varchar(20)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
	   @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 	

set @searchText=REPLACE(@searchText, ' ', '%')

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  
--------

select c.ID_post as cod,RTRIM(c.Descriere) as info,RTRIM(c.ID_post)as denumire
from RU_posturi c
where (c.ID_post like @searchText + '%' or c.Descriere like '%'+@searchText + '%')
order by c.ID_post

for xml raw
end
