
CREATE PROCEDURE wScriuStariDocumente @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @tipDocument VARCHAR(2), @stare INT, @denumire VARCHAR(50), @update BIT, @mesaj VARCHAR(500), @idStare INT,
	@culoare varchar(20), @modificabil bit, @inCurs bit, @initializare bit

	SET @tipDocument = @parXML.value('(/*/@tipdocument)[1]', 'varchar(2)')
	SET @stare = @parXML.value('(/*/@stare)[1]', 'int')
	SET @idStare = @parXML.value('(/*/@idStare)[1]', 'int')
	SET @denumire = @parXML.value('(/*/@denumire)[1]', 'varchar(60)')
	SET @update = isnull(@parXML.value('(/*/@update)[1]', 'bit'), 0)
	SET @modificabil = isnull(@parXML.value('(/*/@modificabil)[1]', 'bit'), 1)
	SET @culoare = @parXML.value('(/*/@culoare)[1]', 'varchar(20)')
	SET @inCurs = isnull(@parXML.value('(/*/@inCurs)[1]', 'bit'), 0)
	SET @initializare = isnull(@parXML.value('(/*/@initializare)[1]', 'bit'), 0)

	IF isnull(@tipDocument, '') = ''
		RAISERROR ('Tip necompletat', 11, 1)

	IF isnull(@denumire, '') = ''
		RAISERROR ('Denumirea starii necompletata', 11, 1)

	IF @update = 0
	BEGIN
		INSERT INTO StariDocumente (tipDocument, stare, denumire, culoare, modificabil,inCurs,initializare)
		VALUES (@tipDocument, @stare, @denumire, @culoare, @modificabil,@inCurs, @initializare)
	END
	ELSE
	BEGIN
		UPDATE StariDocumente
		SET stare = @stare, denumire = @denumire, culoare=@culoare, modificabil=@modificabil, inCurs=@inCurs, initializare=@initializare
		WHERE idStare = @idStare
	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuStariDocumente)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
