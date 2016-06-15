/****** Object:  StoredProcedure [dbo].[wRUACCatCompetente]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE  [dbo].[wRUACCatCompetente]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wRUACCatCompetenteSP' and type='P')      
	exec wRUACCatCompetenteSP @sesiune,@parXML      
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

select c.ID_categ_comp as cod, rtrim(c.Denumire) as denumire,RTRIM(c.Descriere) as info
from RU_categ_comp c
where (c.ID_categ_comp like @searchText + '%' or c.Denumire like '%' + @searchText + '%' or c.Descriere like '%' + @searchText + '%')
order by c.ID_categ_comp

for xml raw
end
