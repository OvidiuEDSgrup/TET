/****** Object:  StoredProcedure [dbo].[wUAACFormular]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE [dbo].[wUAACFormular]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACCasieriSP' and type='P')      
	exec wUAACFormularSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@tip varchar(2)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
	   @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 	

set @searchText=REPLACE(@searchText, ' ', '%')
	select rtrim(numar_formular) as cod, rtrim(numar_formular)+' - '+rtrim(Denumire_formular) as denumire
	from antform
	where (Numar_formular like @searchText + '%' or Denumire_formular like '%' + @searchText + '%')
	  and Tip_formular in('U')
	order by rtrim(Denumire_formular)  

for xml raw
end
