--***
create procedure [dbo].[wStergDevize] @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml ,
        @coddeviz varchar(20)
        
Set @coddeviz = @parXML.value('(/row/@coddeviz)[1]','varchar(20)')

begin try
exec sp_xml_preparedocument @iDoc output, @parXML

delete devauto
	from devauto p, 
	OPENXML (@iDoc, '/row')
	    where  Cod_deviz=@coddeviz
	exec sp_xml_removedocument @iDoc 

	--select 'ok' as msg for xml raw
	exec wIaDevizeLucru @sesiune=@sesiune, @parXML=@parXML

end try
 
	begin catch
		--ROLLBACK TRAN
		
		declare @mesaj varchar(255)
		if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
			set @mesaj=ERROR_MESSAGE()
		raiserror(@mesaj, 11, 1)
		--select @eroare FOR XML RAW
	end catch
