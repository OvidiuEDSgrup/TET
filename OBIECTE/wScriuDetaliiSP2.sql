IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'wScriuDetaliiSP2'
		)
	DROP PROCEDURE wScriuDetaliiSP2
GO

CREATE PROCEDURE wScriuDetaliiSP2 @parXML XML
AS
DECLARE @tabel VARCHAR(20), @detalii XML, @comanda NVARCHAR(max), @eroare VARCHAR(500), @subunitate VARCHAR(10)

SET @tabel = @parXML.value('(/*/@tabel)[1]', 'varchar(20)')
if @parXML.exist('(/*/detalii)[1]')=1
	SET @detalii = @parXML.query('(/*/detalii/row)[1]')

BEGIN TRY
	IF ISNULL(@tabel, '') = ''
		RETURN
		
	IF @tabel = 'pozcon'
		AND EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'pozcon'
				AND sc.NAME = 'detalii'
			)
	BEGIN
		DECLARE @sbCon VARCHAR(10), @con VARCHAR(20), @tertCon VARCHAR(20), @tipCon VARCHAR(10), @dataCon DATETIME, @codCon varchar(20)

		SET @sbCon = @parXML.value('(/*/@subunitate)[1]', 'varchar(10)')
		SET @con = @parXML.value('(/*/@contract)[1]', 'varchar(20)')
		SET @tertCon = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
		SET @tipCon = @parXML.value('(/*/@tip)[1]', 'varchar(10)')
		SET @dataCon = @parXML.value('(/*/@data)[1]', 'datetime')
		SET @codCon = @parXML.value('(/*/@cod)[1]', 'varchar(20)')
		SET @comanda = 'update pozcon SET detalii = @detalii 
				where subunitate=@sbCon and tip=@tipCon and contract=@con and data=@dataCon and tert=@tertCon and cod=@codCon'
		--select @comanda
		exec sp_executesql @statement=@comanda, @params=N'@detalii as xml, @sbCon varchar(10), @tipCon varchar(10), @con VARCHAR(20), @dataCon datetime, @tertCon varchar(20), @codCon varchar(20)',
			@detalii = @detalii, @sbCon = @sbCon, @tipCon = @tipCon, @con = @con, @dataCon = @dataCon, @tertCon = @tertCon, @codCon = @codCon
		RETURN
	END

END TRY

BEGIN CATCH
	SET @eroare = ERROR_MESSAGE() + '(wScriuDetaliiSP2)'

	RAISERROR (@eroare, 11, 1)
END CATCH
