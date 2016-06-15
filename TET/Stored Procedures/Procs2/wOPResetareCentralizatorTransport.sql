
CREATE PROCEDURE wOPResetareCentralizatorTransport @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY	

	truncate table tmpArticoleCentralizatorTransport
	
END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
