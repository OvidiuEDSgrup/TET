
create procedure wStergStructLM (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500), @nivel int

begin try
	set @nivel = @parXML.value('(/row/@nivel)[1]','int')

	if isnull(@nivel,0) <> 0
		delete from strlm where Nivel=@nivel
end try

begin catch
	set @mesaj = error_message() + ' (wStergStructLM)'
	raiserror(@mesaj, 11, 1)
end catch
