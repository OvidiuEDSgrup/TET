/****** Object:  StoredProcedure [dbo].[wUAIaPozInc]    Script Date: 01/05/2011 23:52:44 ******/
--***
create PROCEDURE  [dbo].[wUAIaPozInc]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
	set transaction isolation level READ UNCOMMITTED
	Declare  @abonat varchar(13),@data_inc datetime,@doc varchar(8)

	select 
		@abonat = isnull(@parXML.value('(/row/@abonat)[1]','varchar(13)'),''),
		@data_inc=ISNULL(@parXML.value('(/row/@data_inc)[1]', 'datetime'), ''),
		@doc=ISNULL(@parXML.value('(/row/@doc)[1]', 'varchar(8)'), '')   

	select rtrim(a.abonat)as abonat,rtrim(f.factura) as factura,a.id_factura as id_factura, convert(decimal(12,3),a.Suma) as suma,
		   convert(decimal(12,3),a.Penalizari) as penalizari,            
	       convert(varchar, a.Data, 101)  as data,'IF' as subtip,Document as doc
	from IncasariFactAbon a left outer join AntetFactAbon f on a.id_factura=f.Id_factura
	where a.Document=@doc  
	order by a.data
	for xml raw  
end

--sp_help incasarifactabon
