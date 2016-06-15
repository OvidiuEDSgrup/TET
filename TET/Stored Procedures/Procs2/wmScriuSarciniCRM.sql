
/** Procedura scriere sarcini CRM pentru Mobile */
CREATE PROCEDURE wmScriuSarciniCRM @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE
		@utilizator varchar(50), @descriere varchar(150), @data datetime,
		@termen datetime, @tip_sarcina varchar(30), @prioritate int,
		@sarcina int, @idPotential int, @marca varchar(20), @xml xml, @update bit

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT
		@descriere = RTRIM(@parXML.value('(/row/@descriere)[1]', 'varchar(150)')),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@termen = @parXML.value('(/row/@termen)[1]', 'datetime'),
		@idPotential = @parXML.value('(/row/@idPotential)[1]', 'varchar(50)'),
		@tip_sarcina = RTRIM(@parXML.value('(/row/@tip_sarcina)[1]', 'varchar(30)')),
		@sarcina = @parXML.value('(/row/@sarcina)[1]', 'int'),
		@prioritate = ISNULL(@parXML.value('(/row/@prioritate)[1]', 'int'), 3)

	IF ISNULL(@descriere, '') = ''
		RAISERROR('Introduceti o descriere pentru sarcina!', 16, 1)

	IF ISNULL(@tip_sarcina, '') = ''
		RAISERROR('Specificati tipul sarcinii!', 16, 1)

	SELECT TOP 1 @marca = RTRIM(p.marca)
	FROM personal p, proprietati pr
	WHERE pr.Tip = 'UTILIZATOR' AND pr.Cod = @utilizator AND pr.Cod_proprietate = 'MARCA' AND pr.Valoare = p.Marca

	/** Daca nu se trimite id-ul sarcinii se va face insert, altfel setam variabila @update. */
	IF @sarcina IS NULL
		SET @update = 0
	ELSE
		SET @update = 1

	/** Formam xml-ul cu datele primite din Mobile si il trimitem mai departe la wScriuSarciniCRM */
	SET @xml =
	(
		SELECT
			@sarcina AS idSarcina, @idPotential AS idPotential, @tip_sarcina AS tip_sarcina, @marca AS marca, @descriere AS descriere,
			@termen AS termen, @prioritate AS prioritate, @data AS data, @update AS [update], 1 AS fara_mesaje
		FOR XML RAW, TYPE
	)
	EXEC wScriuSarciniCRM @sesiune = @sesiune, @parXML = @xml

	SELECT 'back(1)' AS actiune
	FOR XML RAW, ROOT('Mesaje')

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
