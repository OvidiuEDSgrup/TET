
CREATE PROCEDURE wScriuPlajeDocumente @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@tip VARCHAR(3), @serie VARCHAR(9), @numarInf INT, @numarSup INT, @ultimulNr INT, @serieInNr INT, @update BIT, @mesaj VARCHAR(500), @idPlaja INT,
		@meniu varchar(20), @subtip varchar(2), @descriere varchar(1000), @dela datetime, @panala datetime

	SELECT
		@tip = @parXML.value('(/*/@tipdocument)[1]', 'varchar(3)'),
		@meniu = @parXML.value('(/*/@meniupl)[1]', 'varchar(20)'),
		@subtip = @parXML.value('(/*/@subtippl)[1]', 'varchar(3)'),
		@serie = @parXML.value('(/*/@serie)[1]', 'varchar(9)'),
		@numarInf = @parXML.value('(/*/@numarinferior)[1]', 'int'),
		@numarSup = @parXML.value('(/*/@numarsuperior)[1]', 'int'),
		@ultimulNr = @parXML.value('(/*/@ultimulnumar)[1]', 'int'),
		@serieInNr = @parXML.value('(/*/@serieinnumar)[1]', 'int'),
		@idPlaja = @parXML.value('(/*/@idPlaja)[1]', 'int'),
		@descriere= @parXML.value('(/*/@descriere)[1]', 'varchar(1000)'),
		@update = isnull(@parXML.value('(/*/@update)[1]', 'bit'), 0),
		@dela = isnull(@parXML.value('(/*/@dela)[1]', 'datetime'), '1901-01-01'),
		@panala = isnull(@parXML.value('(/*/@panala)[1]', 'datetime'), '2901-01-01')

	IF @tip IS NULL or not exists (select 1 from dbo.wfIaTipuriDocumente(null) where tip=@tip)
		RAISERROR ('Tip document necompletat sau inexistent', 11, 1)

	IF @numarInf IS NULL
		OR @numarSup IS NULL
		RAISERROR ('Interval plaja [numarInferior,numarSuperior] necompletat', 11, 1)

	IF @numarInf >= @numarSup
		RAISERROR ('Plaja configurata incorect (numarInferior > numarSuperior)', 11, 1)

	IF @update = 0
	BEGIN
		IF @ultimulNr = 0
			SET @ultimulNr = @numarInf - 1

		INSERT INTO docfiscale (tipDoc, Serie, NumarInf, NumarSup, UltimulNr, SerieInNumar, meniu, subtip, descriere, dela, panala)
		VALUES (@tip, @serie, @numarInf, @numarSup, @ultimulNr, @serieInNr, @meniu, @subtip, @descriere, @dela, @panala)
	END
	ELSE
	BEGIN
		UPDATE docfiscale SET 
			serie = @serie, numarInf = @numarInf, numarSup = @numarSup, UltimulNr=@ultimulNr, SerieInNumar=@serieInNr,meniu=@meniu, subtip=@subtip, 
			descriere=@descriere, dela=@dela, panala=@panala
		WHERE id = @idPlaja
	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPlajeDocumente)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
