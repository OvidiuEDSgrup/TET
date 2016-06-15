
CREATE PROCEDURE wOPDeschidereInventar @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@mesaj VARCHAR(400), @tip VARCHAR(2), @tipinventar VARCHAR(1), @data DATETIME, @gestiune VARCHAR(20), @grupa varchar(13),@locatie varchar(20),
		@detalii xml

	SET @gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)')
	SET @grupa = @parXML.value('(/*/@grupa)[1]', 'varchar(13)')
	SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
	SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @tipinventar = isnull(@parXML.value('(/*/@tipinventar)[1]', 'varchar(2)'),(case when @tip='ID' then 'G' else 'M' end))
	SET @locatie = @parXML.value('(/*/@locatie)[1]', 'varchar(20)')

	IF @parXML.exist('(/*/detalii)[1]') = 1
			SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	IF isnull(@gestiune, '') = ''
		RAISERROR ('Trebuie completat campul cod', 11, 1)

	INSERT INTO AntetInventar (tip, data, gestiune, grupa, stare,locatie,detalii)
	SELECT @tipinventar, @data, @gestiune, @grupa,0, @locatie, @detalii
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPDeschidereInventar)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
