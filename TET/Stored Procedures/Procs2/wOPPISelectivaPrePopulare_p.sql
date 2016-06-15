
CREATE PROCEDURE wOPPISelectivaPrePopulare_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @data DATETIME,  @mesaj varchar(50),@tipOperatiune varchar(1)

	select  @tipOperatiune = @parXML.value('(/*/@tipOperatiune)[1]', 'varchar(1)'),
		@data = @parXML.value('(/*/@data)[1]', 'datetime')	
	
	select convert(char(10), @data, 101) as data
	for xml raw,root('Date')
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPISelectivaPrePopulare_p)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
