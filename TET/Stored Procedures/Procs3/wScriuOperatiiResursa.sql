
CREATE PROCEDURE wScriuOperatiiResursa @sesiune VARCHAR(50), @parXML XML
AS
begin try
	DECLARE @idRes INT, @idOpRes INT, @codOpRes VARCHAR(16), @capacitateOpRes FLOAT, @update BIT, @mesaj varchar(max)

	SET @idRes = ISNULL(@parXML.value('(/row/@id)[1]', 'int'), 0)
	SET @idOpRes = ISNULL(@parXML.value('(/row/row/@id)[1]', 'int'), 0)
	SET @codOpRes = ISNULL(@parXML.value('(/row/row/@cod)[1]', 'varchar(16)'), '')
	SET @capacitateOpRes = ISNULL(@parXML.value('(/row/row/@capacitate)[1]', 'float'), 0)
	SET @update = ISNULL(@parXML.value('(/row/row/@update)[1]', 'bit'), 0)

	IF @capacitateOpRes = 0
		OR @codOpRes = ''
	BEGIN
		RAISERROR ('Cod necompletat sau capacitate introdusa egala cu zero!', 11, 1)
	END

	IF @update = 0
	BEGIN
		INSERT INTO OpResurse (cod, idRes, capacitate)
		VALUES (@codOpRes, @idRes, @capacitateOpRes)
	END
	ELSE
		IF @update = 1
		BEGIN
			UPDATE OpResurse
			SET capacitate = @capacitateOpRes, cod = @codOpRes
			WHERE id = @idOpRes
		END
end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wScriuOperatiiResursa)'
	raiserror(@mesaj, 11, 1)
end catch
