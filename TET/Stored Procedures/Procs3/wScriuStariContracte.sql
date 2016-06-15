
CREATE PROCEDURE wScriuStariContracte @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@tipContract VARCHAR(2), @stare INT, @denumire VARCHAR(50), @update BIT, @mesaj VARCHAR(500), @idStare INT,
		@culoare varchar(20), @modificabil bit, @facturabil bit, @transportabil bit, @inchisa bit, @actaditional bit

	SET @tipContract = @parXML.value('(/*/@tipcontract)[1]', 'varchar(2)')
	SET @stare = @parXML.value('(/*/@stare)[1]', 'int')
	SET @idStare = @parXML.value('(/*/@idStare)[1]', 'int')
	SET @denumire = @parXML.value('(/*/@denumire)[1]', 'varchar(60)')
	SET @update = isnull(@parXML.value('(/*/@update)[1]', 'bit'), 0)
	SET @modificabil = isnull(@parXML.value('(/*/@modificabil)[1]', 'bit'), 1)
	SET @facturabil = isnull(@parXML.value('(/*/@facturabil)[1]', 'bit'), 0)
	SET @transportabil = isnull(@parXML.value('(/*/@transportabil)[1]', 'bit'), 0)
	SET @inchisa = isnull(@parXML.value('(/*/@inchisa)[1]', 'bit'), 0)
	SET @actaditional = isnull(@parXML.value('(/*/@actaditional)[1]', 'bit'), 0)
	SET @culoare = @parXML.value('(/*/@culoare)[1]', 'varchar(20)')

	IF isnull(@tipContract, '') = ''
		RAISERROR ('Tip necompletat', 11, 1)

	IF isnull(@denumire, '') = ''
		RAISERROR ('Denumirea starii necompletata', 11, 1)

	IF @update = 0
	BEGIN
		INSERT INTO StariContracte (tipContract, stare, denumire, culoare, modificabil, facturabil,transportabil, inchisa, actaditional)
		VALUES (@tipContract, @stare, @denumire, @culoare, @modificabil, @facturabil,@transportabil, @inchisa, @actaditional)
	END
	ELSE
	BEGIN
		UPDATE StariContracte
		SET stare = @stare, denumire = @denumire, culoare=@culoare, modificabil=@modificabil, facturabil=@facturabil, transportabil=@transportabil, inchisa=@inchisa, actaditional=@actaditional
		WHERE idStare = @idStare
	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuStariContracte)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
