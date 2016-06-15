/****** Object:  StoredProcedure [dbo].[wUAScriuPozInc]    Script Date: 01/05/2011 23:58:06 ******/
--***
create PROCEDURE  [dbo].[wUAScriuPozInc] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
	set transaction isolation level READ UNCOMMITTED
	
begin try	
	Declare  @abonat varchar(13),@data_inc datetime,@doc int,@new_suma float,@new_id_factura int,@update bit,@subtip varchar(2),
	         @utilizator varchar(13),@tipinc varchar(2),@mesajeroare varchar(200),@nr_fact_avans varchar(13),@id_fact_avans int,
	         @tip_inc varchar(2),@lm varchar(13),@cHostid varchar(10),@i int,@cTextSelect varchar(max) 
	select @utilizator=id from utilizatori where observatii=suser_name()  
	

	select 
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@subtip= isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
		@abonat = isnull(@parXML.value('(/row/@abonat)[1]','varchar(13)'),''),		
		@data_inc=ISNULL(@parXML.value('(/row/row/@data)[1]', 'datetime'), ''),
		@doc=ISNULL(@parXML.value('(/row/@doc)[1]', 'int'), 0)  ,
		@new_id_factura = isnull(@parXML.value('(/row/row/@id_factura)[1]','varchar(13)'),''),
		@new_suma=ISNULL(@parXML.value('(/row/row/@suma)[1]', 'float'), 0),		
		@tipinc = isnull(@parXML.value('(/row/@tip_inc)[1]','varchar(2)'),'0'),
		@utilizator=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
		
		
	set @i = (SELECT min(clmns.max_length) FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id where tbl.name='avnefac' and clmns.name= 'terminal' )       
	set @cHostid=LEFT(@utilizator,@i)	
	IF OBJECT_ID('tempdb..##rasp'+@cHostID) IS NOT NULL
		begin 
			set @cTextSelect='drop table ##rasp'+@cHostID 
			--print @cTextSelect 
			exec (@cTextSelect) 
		end
		
		

	if  @data_inc='' 
		set @data_inc=CONVERT(char(101),getdate(),101)
	if 	@subtip='IF' and @update=0
	    begin
			set @lm=(select isnull(loc_de_munca,'') from UAFactAbon where id_factura=@new_id_factura  )
			exec UAScriuIncasare 'IF',@tipinc,@doc output,@data_inc,@abonat,@lm,@new_id_factura,
								 @new_suma,0,0,@utilizator,0,@utilizator
		end        
		      
	if 	@subtip='IA' and @update=0
			exec UAScriuAvans @abonat,@new_suma,@data_inc,0,@utilizator,'',@tipinc,'AV',@doc output,@nr_fact_avans output,@id_fact_avans output
	       
	if 	@subtip='IF' and @update=1
		update IncasariFactAbon set Suma=@new_suma
		where Abonat=@abonat and Document=@doc and id_factura=@new_id_factura	
	

	if 	@subtip='IA' and @update=1
		update IncasariFactAbon set Suma=@new_suma
		where Abonat=@abonat and Data=@data_inc and Document=@doc and id_factura=@new_id_factura	
	    
	declare @docXML xml
	set @docXML='<row doc="'+rtrim(@doc)+'"/>'
	exec wUAIaInc @sesiune=@sesiune, @parXML=@docXML
	
	declare @docXML1 xml
	set @docXML1='<row doc="'+rtrim(@doc)+'"/>'
	exec wUAIaPozInc @sesiune=@sesiune, @parXML=@docXML1

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch   
end
--select * from incasarifactabon
