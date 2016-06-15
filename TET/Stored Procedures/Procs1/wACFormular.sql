/****** Object:  StoredProcedure [dbo].[wACFormular]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE wACFormular @sesiune [varchar](50),@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wACFormularSP' and type='P')      
	exec wACFormularSP @sesiune,@parXML      
else      
begin
	declare @searchText varchar(80),@meniu varchar(2),@tip varchar(2),@subtip varchar(2)
	  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
		@meniu=ISNULL(@parXML.value('(/row/@codMeniu)[1]', 'varchar(2)'), ''),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '') 	
	set @searchText=REPLACE(@searchText, ' ', '%')

	select rtrim(a.numar_formular) as cod, rtrim(a.numar_formular)+' - '+rtrim(a.Denumire_formular)as denumire 
	FROM antform a 
		inner join xmlformular x on a.Numar_formular=x.Numar_formular and x.Continut is not null 
	WHERE (a.Numar_formular like @searchText + '%' or a.Denumire_formular like '%'+@searchText+'%') 
		and a.Tip_formular=(case when @tip='RK' and @subtip='KE' then 'F' when @meniu='MF' then 'X' 
			when @subtip='GP' then 'A'  -->penalitati UC
			when @meniu='FP' then 'W'  -->formulare PS
			when @meniu='FL' then '6'  -->fluturasi PS
			else 'U' end)
	ORDER BY rtrim(a.Denumire_formular)
	for xml raw
end
--select * from xmlformular
