
CREATE PROCEDURE wScriuAsocieriPlaja @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tip VARCHAR(1), @cod VARCHAR(20), @prioritate INT, @mesaj VARCHAR(500), @update BIT, @idPlaja INT

	SET @idPlaja = @parXML.value('(/*/@idPlaja)[1]', 'int')
	SET @update = isnull(@parXML.value('(/*/*/@update)[1]', 'bit'), 0)
	SET @tip = @parXML.value('(/*/*/@tipasociere)[1]', 'varchar(1)')
	SET @cod = @parXML.value('(/*/*/@cod)[1]', 'varchar(20)')
	/** La tip: Unitate nu se completaza cod **/
	IF @tip = ''
		SET @cod = ''
	SET @prioritate = @parXML.value('(/*/*/@prioritate)[1]', 'int')

	IF @tip <> ''
		AND isnull(@cod,'') =''
		RAISERROR ('Codul este necompletat!', 11, 1)

	IF @update = 0
	BEGIN
		INSERT INTO asocieredocfiscale (id, tipasociere, cod, prioritate)
		VALUES (@idPlaja, @tip, @cod, @prioritate)
	END
	ELSE
	BEGIN
		DECLARE @o_tip VARCHAR(1), @o_cod varchar(20)

		SELECT
			@o_tip = @parXML.value('(/*/*/@o_tipasociere)[1]', 'varchar(1)'),
			@o_cod = @parXML.value('(/*/*/@o_cod)[1]', 'varchar(20)')

		UPDATE asocieredocfiscale
		SET tipAsociere = @tip, cod = @cod, prioritate=@prioritate
		WHERE id = @idPlaja
			AND tipAsociere = @o_tip and cod=@o_cod 
	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuAsocieriPlaja)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
