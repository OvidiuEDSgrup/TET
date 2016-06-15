/****** Object:  StoredProcedure [dbo].[wRUACIerarhii]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE  [dbo].[wRUACIerarhii]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wRUACIerarhiiSP' and type='P')      
	exec wRUACIerarhiiSP @sesiune,@parXML      
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

select c.ID_ierarhie as cod, 'Nivel ierarhic: '+CONVERT(varchar,c.nivel_ierarhic) as denumire
from RU_ierarhii c
where (c.ID_ierarhie like @searchText + '%' or c.Nivel_ierarhic like  @searchText + '%')
order by c.ID_ierarhie

for xml raw
end
