/****** Object:  StoredProcedure [dbo].[wUAIaPozInc]    Script Date: 01/05/2011 23:52:44 ******/
--***
create PROCEDURE [dbo].[wUAIaPozIncasariAbonati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
	set transaction isolation level READ UNCOMMITTED
	Declare  @abonat varchar(13),@data_inc datetime,@doc varchar(10)

	select 
		@doc=ISNULL(@parXML.value('(/row/@document)[1]', 'varchar(10)'), '')   

	select rtrim(a.abonat)as abonat,rtrim(f.factura) as factura,a.id_factura as id_factura, convert(decimal(12,3),a.Suma) as suma,convert(decimal(12,3),a.Penalizari) as penalizari,            
	       convert(varchar, a.Data, 101)  as data,Document as document,RTRIM(a.tip) as tip,'MI'as subtip,
	       (case when a.Tip='IA' then 'Inc. Avans' when a.Tip='IF' then 'Inc. Factura'else a.Tip end)as denTip
	       --(case when a.Tip='AV' then 'AV' when a.tip='IF' then 'IF' else '' end) as subtip 
	
	from IncasariFactAbon a left outer join AntetFactAbon f on a.id_factura=f.Id_factura
	where a.Document=@doc  
	order by a.data
	for xml raw  
end
--select * from incasarifactabon
--select * from antetfactabon
