--***
/****** Object:  StoredProcedure [dbo].[wUAStergPozIncasariAbonati]    Script Date: 01/05/2011 23:08:45 ******/
create procedure  [dbo].[wUAStergPozIncasariAbonati]  @sesiune varchar(50), @parXML xml
as
begin try
	DECLARE @id_factura int,@nr_pozitie int ,@doc varchar(10),@subtip varchar(2)      
     select
         @id_factura = isnull(@parXML.value('(/row/row/@id_factura)[1]','int'),''),
         @subtip=isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
         @doc = isnull(@parXML.value('(/row/@document)[1]','varchar(10)'),'')        
         
declare @mesajeroare varchar(100)
begin
	--select @id_factura,@doc
	
	if (select rtrim(tip) from IncasariFactAbon where Id_factura=@id_factura and Document=@doc)='IA'
		begin
			delete from AntetFactAbon where Id_factura=@id_factura
			delete from PozitiiFactAbon where Id_factura=@id_factura
			delete from IncasariFactAbon where Id_factura=@id_factura and Document=@doc
		end
	else
	   	delete from IncasariFactAbon where Id_factura=@id_factura and Document=@doc

declare @docXML xml
	set @docXML='<row document="'+rtrim(@doc)+'"/>'
	exec wUAIaPozIncasariAbonati @sesiune=@sesiune, @parXML=@docXML
end	

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
--select * from IncasariFactAbon
