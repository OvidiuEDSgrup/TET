
CREATE PROCEDURE wScriuMasiniTert @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	
	DECLARE @nr_masina varchar(50), @descriere_masina varchar(150), @tert varchar(50),
		@delegat varchar(50), @update bit, @o_nr_masina varchar(50)

	SELECT @tert = ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(50)'), ''),
		@nr_masina = ISNULL(@parXML.value('(/row/row/@nr_masina)[1]', 'varchar(50)'), ''),
		@descriere_masina = ISNULL(@parXML.value('(/row/row/@descriere_masina)[1]', 'varchar(150)'), ''),
		@delegat = ISNULL(@parXML.value('(/row/row/@delegat)[1]', 'varchar(50)'), ''),
		@update = ISNULL(@parXML.value('(/row/row/@update)[1]', 'bit'), 0),
		@o_nr_masina = @parXML.value('(/row/row/@o_nr_masina)[1]', 'varchar(50)')

	IF @tert = ''
		RAISERROR('Nu s-a putut identifica tertul!', 16, 1)

	IF @nr_masina = ''
		RAISERROR('Completati masina!', 16, 1)

	IF @update = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM masinexp WHERE Furnizor = @tert AND Numarul_mijlocului = @nr_masina)
			RAISERROR('Masina existenta pe acest tert!', 16, 1)

		INSERT INTO masinexp (Numarul_mijlocului, Descriere, Furnizor, Delegat)
		SELECT @nr_masina, @descriere_masina, @tert, @delegat
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM masinexp WHERE Furnizor = @tert AND Numarul_mijlocului = @nr_masina) AND (@o_nr_masina <> @nr_masina)
			RAISERROR('Masina existenta pe acest tert!', 16, 1)

		UPDATE masinexp
		SET Numarul_mijlocului = @nr_masina, Descriere = @descriere_masina,
			Delegat = @delegat
		WHERE Furnizor = @tert AND Numarul_mijlocului = @o_nr_masina
	END

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
