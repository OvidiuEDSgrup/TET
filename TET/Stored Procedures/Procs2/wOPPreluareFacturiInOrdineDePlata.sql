
CREATE PROCEDURE wOPPreluareFacturiInOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@idOP INT, @docPozitii XML, @data DATETIME, @cont VARCHAR(20), @conturiFiltru VARCHAR(max), 
		@tert VARCHAR(20), @mesaj VARCHAR(500), @explicatii varchar(500), @tip_sume int

	SET @cont = @parXML.value('(/*/@cont)[1]', 'varchar(20)')
	SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
	SET @tert= @parXML.value('(/*/@tert)[1]', 'varchar(20)')
	SET @explicatii= @parXML.value('(/*/@explicatii)[1]', 'varchar(500)')
	SET @tip_sume= isnull(@parXML.value('(/*/@tip_sume)[1]', 'int'),1)

	IF OBJECT_ID('tempdb..#pozitiiPreluare') IS NOT NULL
		DROP TABLE #pozitiiPreluare

	CREATE TABLE #pozitiiPreluare (tert VARCHAR(20), factura VARCHAR(20), sold float)

	EXEC luare_date_par 'OP', 'CFACTURI', 0, 0, @conturiFiltru OUTPUT

	IF isnull(@conturiFiltru, '') = ''
		SET @conturiFiltru = '401,404'

	INSERT INTO #pozitiiPreluare (tert, factura, sold)
	SELECT rtrim(tert) tert, rtrim(Factura) factura, (case @tip_sume WHEN 1 then sold else 0.0 end)
	FROM facturi f
	INNER JOIN fSplit(@conturiFiltru, ',') fc
		ON f.Cont_de_tert LIKE fc.string + '%'
	WHERE f.tip = 0x54
		AND Data_scadentei <= @data
		AND sold > 0.0001
		and (ISNULL(@tert,'')='' or f.Tert=@tert)
	ORDER BY f.Tert


	SET @docPozitii = (
			select
				'1' AS preluare, @data data, @cont cont, 'F' sursa,'1' fara_luare_date,'FA' tip,'FA' tipOP,@explicatii explicatii,
				(
					select
						@idOP idOP,rtrim(p.tert) tert, rtrim(p.factura) factura, rtrim(t.banca) banca, rtrim(t.cont_in_banca) iban, 'FA' tip, p.sold suma,
						'0' stare,	'Factura '+rtrim(p.factura) explicatii
					from #pozitiiPreluare p
					LEFT JOIN terti t ON t.Tert = p.tert
					for xml raw, type
				)
			for xml raw)


	EXEC wScriuPozOrdineDePlata @sesiune = @sesiune, @parXML = @docPozitii
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPreluareFacturiInOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
