
--***

CREATE PROCEDURE wStergConfigurareContareIG @sesiune varchar(50), @parXML xml
AS

	DECLARE	@mesaj varchar(500), @cont_de_stoc varchar(20), @utilizator varchar(50)

BEGIN TRY
	
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @cont_de_stoc = ISNULL(@parXML.value('(/*/@cont_de_stoc)[1]', 'varchar(20)'),'')

	IF @cont_de_stoc = ''
		BEGIN
			SET @mesaj = 'Cont de stoc inexistent.'
			RAISERROR(@mesaj,16,1)
		END
	ELSE
		BEGIN
			DELETE FROM ConfigurareContareIesiriDinGestiune WHERE cont_de_stoc = @cont_de_stoc
		END

	EXEC wIaConfigurareContareIG @sesiune, @parXML

END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + '(wStergConfigurareContareIG)'
	RAISERROR(@mesaj, 11, 1)	
END CATCH
