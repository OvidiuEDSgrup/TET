
CREATE PROCEDURE wScriuBanci @sesiune varchar(50), @parXML xml
AS

DECLARE
	@utilizator varchar(50), @codbanca varchar(50), @denbanca varchar(100),
	@filiala varchar(60), @judet varchar(40), @tip varchar(1), @update int,
	@codbancaOld varchar(50), @mesaj varchar(100)

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT 
		@codbanca = ISNULL(@parXML.value('(/row/@codbanca)[1]','varchar(50)'), ''),
		@denbanca = ISNULL(@parXML.value('(/row/@denbanca)[1]','varchar(100)'), ''),
		@filiala = ISNULL(@parXML.value('(/row/@filiala)[1]','varchar(60)'), ''),
		@judet = ISNULL(@parXML.value('(/row/@judet)[1]','varchar(40)'), ''),
		@tip = ISNULL(@parXML.value('(/row/@tip)[1]','varchar(1)'), ''),
		@update = ISNULL(@parXML.value('(/row/@update)[1]','int'), 0),
		@codbancaOld = ISNULL(@parXML.value('(/row/@o_codbanca)[1]','varchar(50)'), '')

	IF @update = 1 AND @codbancaOld <> @codbanca
	BEGIN
		RAISERROR('Codul bancii nu poate fi modificat!', 11, 1)
		RETURN -1
	END

	IF @update = 0
	BEGIN
	--validari

		INSERT INTO bancibnr(Cod, Denumire, Filiala, Judet, Tip)
		SELECT @codbanca, @denbanca, @filiala, @judet, @tip
	END
	ELSE 
	BEGIN
		UPDATE bancibnr 
			SET Cod = @codbanca, Denumire = @denbanca, Filiala = @filiala,Judet = @judet, Tip = @tip
		WHERE Cod = @codbanca
	END 

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuBanci)'
	RAISERROR(@mesaj, 11, 1)
END CATCH
