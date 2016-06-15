
CREATE PROCEDURE wOPDocIesireSelectiva @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @xml xml, @iDoc int, @numar varchar(20), @lm varchar(20), @gestiune varchar(20), @sub varchar(10),
		@tip varchar(2), @data datetime, @cod varchar(20), @detaliiPozitii xml, @utilizator varchar(50), @gestprim varchar(50),
		@tert varchar(50), @comanda varchar(50), @datafacturii datetime, @datascadentei datetime, @tiptva int,
		@aviznefacturat bit, @punctlivrare varchar(50), @pvaluta float, @discount float, @detaliiAntet xml

	SET @tiptva = isnull(@parXML.value('(/*/@tiptva)[1]', 'int'), 0)
	SET @numar = isnull(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), '')
	SET @lm = isnull(@parXML.value('(/*/@lm)[1]', 'varchar(20)'), '')
	SET @gestiune = isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'), '')
	SET @tip = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'),'')
	SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'),'')
	SET @cod = isnull(@parXML.value('(/*/@cod)[1]', 'varchar(20)'),'')
	SET @gestprim = isnull(@parXML.value('(/*/@gestprim)[1]', 'varchar(50)'),'')
	SET @tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(50)'), '')
	SET @comanda = isnull(@parXML.value('(/*/@comanda)[1]', 'varchar(50)'), '')
	SET @datafacturii = @parXML.value('(/*/@datafacturii)[1]', 'datetime')
	SET @datascadentei = @parXML.value('(/*/@datascadentei)[1]', 'datetime')
	SET @punctlivrare = isnull(@parXML.value('(/*/@punctlivrare)[1]', 'varchar(50)'), '')
	SET @aviznefacturat = isnull(@parXML.value('(/*/@aviznefacturat)[1]', 'bit'), 0)
	SET @pvaluta = isnull(@parXML.value('(/*/@pvaluta)[1]', 'float'), 0)
	SET @discount = isnull(@parXML.value('(/*/@discount)[1]', 'float'), 0)

	IF @parXML.exist('(/*/detalii/row)[1]') = 1
		SET @detaliiAntet = @parXML.query('(/*/detalii/row)[1]')

	IF @parXML.exist('(/*/*/detalii/row)[1]') = 1
		SET @detaliiPozitii = @parXML.query('(/*/*/detalii/row)[1]')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT

	--> Citire date din grid
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	IF OBJECT_ID('tempdb.dbo.#xmldocs') IS NOT NULL DROP TABLE #xmldocs
	
	SELECT cod_intrare, CONVERT(decimal(17,5), pret) AS pret, CONVERT(decimal(17,2), cantitate) as cantitate,
		contstoc, selectat, factura, valuta, curs, contcorespondent,  detalii
	INTO #xmldocs
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		cod_intrare varchar(50) '@cod_intrare',
		pret float '@pret',
		cantitate float '@cantitate',
		contstoc varchar(50) '@contstoc',
		selectat int '@selectat',
		factura varchar(20) '@factura',
		valuta varchar(3) '@valuta',
		curs float '@curs',
		contcorespondent varchar(40) '@contcorespondent',
		detalii xml 'detalii/row'
	)
	
	EXEC sp_xml_removedocument @iDoc

	/** Creare XML pentru trimitere la wScriuDoc/wScriuDocBeta */
	SET @xml = 
	(
		SELECT RTRIM(@sub) AS subunitate, @tip AS tip, @lm AS lm, CONVERT(varchar(10), @data, 101) AS data, @tiptva as tiptva,
			@gestiune as gestiune, @gestprim AS gestprim, @numar AS numar, 1 as apelDinProcedura,
			@tert as tert, @comanda AS comanda, @datafacturii AS datafacturii, @datascadentei AS datascadentei,
			@aviznefacturat AS aviznefacturat, @detaliiAntet AS detalii,
			(
				SELECT @numar AS numar, @cod AS cod, @gestiune AS gestiune,
					f.cantitate AS cantitate, CONVERT(decimal(17,5), f.pret) AS pstoc, CONVERT(decimal(17,5), @pvaluta) AS pvaluta,
					f.cod_intrare as codintrare, f.contstoc as contstoc, f.contcorespondent as contcorespondent,
					f.factura as factura, f.valuta as valuta, CONVERT(decimal(12,5), f.curs) AS curs,
					CONVERT(decimal(15,2), @discount) AS discount, f.detalii AS detalii
				FROM #xmldocs f
				WHERE ABS(f.cantitate) > 0.001 AND f.selectat = 1
				FOR XML RAW, TYPE
			)
		FOR XML RAW, TYPE
	)
	/*	Apelare wScriuPozdocSP (daca exista, pentru prelucrari in parXML), wScriuDoc sau wScriuDocBeta.	*/
	IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = 'wScriuPozdocSP' AND type = 'P')
		EXEC wScriuPozdocSP @sesiune = @sesiune, @parXML = @xml OUTPUT

	IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = 'wScriuDoc')
		EXEC wScriuDoc @sesiune = @sesiune, @parXML = @xml OUTPUT
	ELSE
		IF EXISTS (SELECT 1 FROM sys.sysobjects WHERE name = 'wScriuDocBeta')
			EXEC wScriuDocBeta @sesiune = @sesiune, @parXML = @xml OUTPUT

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
