
CREATE PROCEDURE wStergPozPlanificareLansari @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare
		@idPlanificare int

	select
		@idPlanificare = @parXML.value('(//@idPlanif)[1]','int')

	delete Planificare where id=@idPlanificare
	
	exec wIaPozPlanificareLansari @sesiune=@sesiune, @parXML=@parXML
END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
