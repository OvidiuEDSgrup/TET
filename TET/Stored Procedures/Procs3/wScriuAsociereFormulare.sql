
CREATE PROCEDURE wScriuAsociereFormulare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idAsoc INT, @meniu VARCHAR(20), @tip VARCHAR(20), @formular VARCHAR(60), @mesaj VARCHAR(500)

	SET @meniu = @parXML.value('(/*/@meniu)[1]', 'varchar(20)')
	SET @tip = @parXML.value('(/*/@tipDoc)[1]', 'varchar(20)')
	SET @formular = @parXML.value('(/*/@formular)[1]', 'varchar(60)')
	set @idAsoc=@parXML.value('(/*/@idAsociere)[1]', 'int')

	if @meniu is null	--> s-ar putea sa fie apel din detalierea asocierilor din formulare
	select	@meniu = @parXML.value('(/*/*/@meniu)[1]', 'varchar(20)'),
			@tip = isnull(@tip,@parXML.value('(/*/*/@tipDoc)[1]', 'varchar(20)')),
			@idAsoc=isnull(@idAsoc,@parXML.value('(/*/*/@idAsociere)[1]', 'int'))

	IF @idAsoc IS NULL
	BEGIN
		IF isnull(@meniu, '') = ''
			OR (not exists (select 1 from webconfigmeniu w where w.meniu=@meniu and tipmacheta iN ('C','M')) and ISNULL(@tip, '') = '')
			OR ISNULL(@formular, '') = ''
			RAISERROR ('Toate campurile trebuie completate pt. o asociere buna!', 11, 1)

		INSERT INTO webConfigFormulare (meniu, tip, cod_formular)
		SELECT @meniu, @tip, @formular
	END
	ELSE
	BEGIN
		UPDATE webConfigFormulare
		SET meniu = @meniu, tip = @tip, cod_formular = @formular
		WHERE idAsociere = @idAsoc
	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuAsociereFormulare)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
