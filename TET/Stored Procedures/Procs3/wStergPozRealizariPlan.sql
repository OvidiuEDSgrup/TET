
CREATE PROCEDURE wStergPozRealizariPlan @sesiune VARCHAR(50), @parXML XML
AS
begin try

	delete from PozRealizari where id=@parXML.value('(/*/@idPozRealizare)[1]','int')

	exec wIaPozRealizariPlan @sesiune=@sesiune, @parXML=@parXML
	
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
