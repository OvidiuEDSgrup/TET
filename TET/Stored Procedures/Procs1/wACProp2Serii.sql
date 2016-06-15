/****** Object:  StoredProcedure [dbo].[wACProp2Serii]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE wACProp2Serii
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wACProp2SeriiSP' and type='P')      
	exec wACProp2SeriiSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@tip varchar(2),@subtip varchar(2),@cod varchar(13)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
	   @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') ,
	   @subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '') ,
	   @cod=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(13)'), '') 	

set @searchText=REPLACE(@searchText, ' ', '%')

if @cod=''
	set @cod=ISNULL(@parXML.value('(/row/linie/@cod)[1]', 'varchar(20)'),'')	
	
	select rtrim(a.Valoare) as cod, rtrim(n.Denumire)+' '+rtrim(a.Valoare) as denumire
	from valprop a
		inner join propgr g on g.Cod_proprietate=a.Cod_proprietate and g.Numar=2
	    inner join nomencl n on n.Cod=a.Cod
	where (a.Valoare  like '%' + @searchText + '%')
	  and (a.Cod=@cod or @cod='')
	order by rtrim(a.Valoare)  

for xml raw
end

--select * from valprop
