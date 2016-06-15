--***
create procedure [dbo].[wStergPozDevizeLucru] @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml ,
        @cod varchar(20)
        
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')

begin try
exec sp_xml_preparedocument @iDoc output, @parXML

delete pozdevauto
	from pozdevauto p, 
	OPENXML (@iDoc, '/row')
	    where  Cod=@cod
	exec sp_xml_removedocument @iDoc 

	--select 'ok' as msg for xml raw
	exec wIaPozDevizeLucru @sesiune=@sesiune, @parXML=@parXML

end try
 
	begin catch
		--ROLLBACK TRAN
		
		declare @mesaj varchar(255)
		if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
			set @mesaj=ERROR_MESSAGE()
		raiserror(@mesaj, 11, 1)
		--select @eroare FOR XML RAW
	end catch
