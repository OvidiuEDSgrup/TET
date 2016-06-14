--***
IF exists (SELECT * FROM sysobjects WHERE name ='wOPStornareDocumentSP_p')
DROP PROCEDURE wOPStornareDocumentSP_p
go
--***
/****** Object:  StoredProcedure [dbo].[wOPModificareAntetCon_p]    Script Date: 04/06/2011 10:58:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
CREATE PROCEDURE wOPStornareDocumentSP_p @sesiune VARCHAR(50), @parXML XML 
AS  
BEGIN TRY
	DECLARE /*date de identificare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(13),
		/*alte variabile necesare:*/@utilizator VARCHAR(20), @eroare VARCHAR(250),@factura VARCHAR(20),@numardoc VARCHAR(8),
		@NrAvizeUnitar INT, @lm VARCHAR(13),@idPozDoc INT--/*SP
		,@CTCLAVRT bit,@ContAvizNefacturat varchar(20)

	exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output
	--SP*/

	SELECT
		--date pt identificare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(8)'), ''),
		@factura=ISNULL(@parXML.value('(/row/@factura)[1]', 'varchar(20)'), ''),
		@idPozDoc=ISNULL(@parXML.value('(/row/@idPozDoc)[1]', 'INT'), ''),
		@lm=ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(13)'), '')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identificare utilizator pe baza sesiunii
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati    
	EXEC luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar OUTPUT, 0, '' 

	IF @numar=''
	BEGIN
		SELECT 'Selectati mai intai documentul pentru stornare!' AS textMesaj FOR XML RAW, ROOT('Mesaje')
		RETURN -1
	END  

	DECLARE @fXML XML, @tipPentruNr VARCHAR(2), @NrDocPrimit VARCHAR(20),@idPlajaPrimit INT, @NumarDocPrimit INT
/*sp
	SET @tipPentruNr=@tip 
	
	IF @NrAvizeUnitar=1 AND @tip='AS' 
		SET @tipPentruNr='AP' 
	SET @fXML = '<row/>'
	SET @fXML.modify  ('insert attribute tipmacheta {"DO"} into (/row)[1]')
	SET @fXML.modify  ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
	SET @fXML.modify  ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
	SET @fXML.modify  ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
	
	EXEC wIauNrDocFiscaleSP @parXML=@fXML, @NrDoc=@NrDocPrimit OUTPUT, @Numar=@NumarDocPrimit OUTPUT, @idPlaja=@idPlajaPrimit OUTPUT

	SET @numardoc=@NrDocPrimit			
		
	--numarul sugerat se introduce in tabela de numere de documente rezervate
	IF EXISTS (	SELECT 1 FROM sys.objects WHERE NAME = 'docfiscalerezervate 'AND TYPE = 'U'	) 
		AND NOT EXISTS (SELECT 1 FROM docfiscalerezervate WHERE numar=@NumarDocPrimit AND idPlaja=@idPlajaPrimit)
	BEGIN	
		INSERT INTO docfiscalerezervate 
			SELECT @idPlajaPrimit,@NumarDocPrimit,DATEADD(mi, 5, GETDATE())
	END
--sp*/

	SELECT --/*sp @numardoc AS facturadoc ,@numardoc AS numardoc, CONVERT(CHAR(10),@data,101) AS dataFactDoc
		top 1 /*p.Factura*/null AS facturadoc 
			,/*CONVERT(CHAR(10),p.Data_facturii,101)*/null AS dataFactDoc
			,/*isnull(d.Numar,@numardoc)*/ '' AS numardoc
			,/*CONVERT(CHAR(10),isnull(d.Data,@data),101)*/ CONVERT(CHAR(10),GETDATE(),101) AS datadoc
			,(case when p.Tip in ('AP','AS') and isnull(d.Cont_factura,p.Cont_factura) =@ContAvizNefacturat then 1 else 0 end ) as aviznefacturat
	FROM pozdoc p
		left JOIN LegaturiStornare s on s.idSursa=p.idPozDoc and 1=0
		left JOIN pozdoc d on d.idPozDoc=s.idStorno
	WHERE p.Subunitate=@sub AND p.tip=@tip
		AND p.data=@data AND p.Numar=@numar --sp*/
	FOR XML RAW, ROOT('Date')
	
	SELECT p.tip AS tip,CONVERT(CHAR(10),p.data,101) AS data,RTRIM(p.subunitate) AS subunitate
		,RTRIM(p.numar) AS numar, p.Numar_pozitie AS numar_pozitie
		,RTRIM(p.cod) AS cod,RTRIM(p.gestiune) AS gestiune,CONVERT(DECIMAL(17,5),p.Cantitate) AS cantitate
		,CONVERT(DECIMAL(17,5),p.Cantitate *(-1)) AS cantitate_storno
		,CONVERT(DECIMAL(17,5),p.Cantitate *(-1)) AS cantitate_stornoMax--cantitatea maxima care poate fi stornata
		,CONVERT(DECIMAL(17,5),p.pret_valuta) AS pvaluta
		,CONVERT(DECIMAL(17, 3), p.cantitate*p.pret_valuta) AS valvaluta 
		,CONVERT(DECIMAL(17, 3), p.cantitate*p.Pret_de_stoc) AS valstoc 
		,CONVERT(DECIMAL(17, 5), p.pret_de_stoc) AS pstoc, CONVERT(DECIMAL(17, 5), p.pret_vanzare) AS pvanzare   
		,CONVERT(DECIMAL(17, 5), p.pret_cu_amanuntul) AS pamanunt, CONVERT(DECIMAL(5, 2), p.cota_tva) AS cotatva   
		,CONVERT(DECIMAL(17, 2), p.TVA_deductibil) AS sumatva, RTRIM(n.Denumire) AS dencod,RTRIM(p.Cod_intrare) AS cod_intrare
		,RTRIM(g.Denumire_gestiune) AS dengestiune			
	INTO #pozitiiDoc		
	FROM pozdoc p 
		LEFT JOIN nomencl n ON n.Cod=p.Cod
		LEFT JOIN gestiuni g ON g.Cod_gestiune=p.Gestiune
	WHERE p.Subunitate=@sub AND p.tip=@tip
		AND p.data=@data AND p.Numar=@numar
		
	IF EXISTS (
		SELECT 1
		FROM syscolumns sc, sysobjects so
		WHERE so.id = sc.id
			AND so.NAME = 'pozdoc'
			AND sc.NAME = 'idPozDoc'
		)
	BEGIN
		ALTER TABLE #pozitiiDoc ADD idPozDoc INT;
			
		UPDATE #pozitiiDoc
		SET idPozDoc = pd.idPozDoc --/*sp 
			,cantitate_storno=cantitate_storno-isnull(c.cant_stornata,0)
			,cantitate_stornoMax=cantitate_stornoMax-isnull(c.cant_stornata,0) --sp*/
		FROM pozdoc pd
			OUTER APPLY (
							SELECT s.idSursa as idSursa, sum(p.Cantitate) as cant_stornata
							FROM pozdoc p
								INNER JOIN LegaturiStornare s on s.idStorno=p.idPozDoc 
									AND s.idSursa=PD.idPozDoc
							GROUP BY s.idSursa
						)c				
			
		WHERE #pozitiiDoc.subunitate = pd.Subunitate
			AND #pozitiiDoc.tip = pd.Tip
			AND #pozitiiDoc.data = pd.Data
			AND #pozitiiDoc.numar = pd.Numar
			AND #pozitiiDoc.gestiune = pd.Gestiune
			AND #pozitiiDoc.cod = pd.Cod
			AND #pozitiiDoc.cod_intrare = pd.Cod_intrare
			AND #pozitiiDoc.numar_pozitie = pd.Numar_pozitie
			AND #pozitiiDoc.pvanzare = pd.Pret_vanzare
			
	END
	
	SELECT (   
		SELECT * 
		FROM  #pozitiiDoc		
		FOR XML RAW, TYPE  
	  )  
	FOR XML PATH('DateGrid'), ROOT('Mesaje')

END TRY	
BEGIN CATCH
	SET @eroare = ERROR_MESSAGE()
	RAISERROR(@eroare, 11, 1)	
END CATCH

/*select * from pozdoc*/