
CREATE PROCEDURE wOPDetaliiExpeditieDocument_p @sesiune VARCHAR(50), @parXML XML
aS
	DECLARE @tert varchar(20), @dentert varchar(20), @expeditie bit, @data_expedierii datetime
	
	SET @expeditie = ISNULL((SELECT val_logica FROM par WHERE Tip_parametru = 'AR' AND Parametru = 'EXPEDITIE'), 0)

	-- daca tertul delegat a fost specificat inainte, ramane acelasi
	SELECT @tert = @parXML.value('(/*/detalii/row/@tertdelegat)[1]','varchar(20)'),
		@data_expedierii = ISNULL(@parXML.value('(/*/detalii/row/@data_expedierii)[1]', 'datetime'), @parXML.value('(//@data)[1]', 'datetime'))

	IF ISNULL(@tert, '') = ''
	BEGIN
		SELECT @tert = @parXML.value('(//@tert)[1]','varchar(20)')
		IF @expeditie = 0
			EXEC luare_date_par 'UC', 'TERTGEN', 0, 0, @tert OUTPUT
	END
	
	SELECT TOP 1 @dentert = RTRIM(Denumire)
	FROM terti WHERE tert = @tert

	SELECT RTRIM(@tert) AS tert, RTRIM(@tert) AS detalii_tertdelegat, @dentert AS detalii_dentertdelegat,
		CONVERT(varchar(10), @data_expedierii, 101) AS detalii_data_expedierii
	FOR XML RAW, ROOT('Date')
