
CREATE PROCEDURE wScriuConfigurareContareIG @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @mesaj varchar(200), @update bit, @cont_de_stoc varchar(20), @cont_cheltuieli varchar(20),
		@cont_venituri varchar(20), @analiticg int, @analiticcs int, @nrord int,
		@o_cont_de_stoc varchar(20), @utilizator varchar(50), @tipdoc varchar(10),
		@o_cont_cheltuieli varchar(20), @o_cont_venituri varchar(20)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	SELECT 
		@cont_de_stoc = ISNULL(@parXML.value('(/*/@cont_de_stoc)[1]', 'varchar(20)'), ''),
		@cont_cheltuieli = ISNULL(@parXML.value('(/*/@cont_cheltuieli)[1]', 'varchar(20)'), ''),
		@cont_venituri = ISNULL(@parXML.value('(/*/@cont_venituri)[1]', 'varchar(20)'), ''),
		@analiticg = ISNULL(@parXML.value('(/*/@analiticg)[1]', 'int'), 0),
		@analiticcs = ISNULL(@parXML.value('(/*/@analiticcs)[1]', 'int'), 0),
		@nrord = ISNULL(@parXML.value('(/*/@nrord)[1]', 'int'), 0),
		@o_cont_de_stoc = ISNULL(@parXML.value('(/*/@o_cont_de_stoc)[1]', 'varchar(20)'), ''),
		@o_cont_cheltuieli = ISNULL(@parXML.value('(/*/@o_cont_cheltuieli)[1]', 'varchar(20)'), ''),
		@o_cont_venituri = ISNULL(@parXML.value('(/*/@o_cont_venituri)[1]', 'varchar(20)'), ''),
		@update = ISNULL(@parXML.value('(/*/@update)[1]', 'bit'), 0),
		@tipdoc = ISNULL(@parXML.value('(/*/@tipdoc)[1]', 'varchar(10)'), '')

	IF @cont_de_stoc = ''
	BEGIN
		SET @mesaj = 'Cont de stoc necompletat!'
		RAISERROR(@mesaj, 16, 1)
	END

	IF @update = 0
	BEGIN
		INSERT INTO ConfigurareContareIesiriDinGestiune(cont_de_stoc, cont_cheltuieli, cont_venituri,
			analiticg, analiticcs, nrord, Tip)
		VALUES (@cont_de_stoc, @cont_cheltuieli, @cont_venituri, @analiticg, @analiticcs, @nrord, @tipdoc)
	END
	ELSE
	BEGIN
		UPDATE ConfigurareContareIesiriDinGestiune
		SET cont_de_stoc = @cont_de_stoc, cont_cheltuieli = @cont_cheltuieli, cont_venituri = @cont_venituri,
			analiticg = @analiticg, analiticcs = @analiticcs, nrord = @nrord, Tip = @tipdoc
		WHERE cont_de_stoc = @o_cont_de_stoc
			AND cont_cheltuieli = @o_cont_cheltuieli
			AND cont_venituri = @o_cont_venituri
	END

	EXEC wIaConfigurareContareIG @sesiune, @parXML

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesaj, 16, 1)
END CATCH
