--***
CREATE PROCEDURE wOPStornareDocument_p @sesiune VARCHAR(50), @parXML XML 
AS  
BEGIN TRY
	DECLARE /*date de identificare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(20),
		/*alte variabile necesare:*/@utilizator VARCHAR(20), @eroare VARCHAR(250),@factura VARCHAR(20),@numardoc VARCHAR(20),
		@NrAvizeUnitar INT, @lm VARCHAR(13),@idPozDoc INT,
		/*pentru identificare bon stornat*/@idantetbon int, @numarBon varchar(100),@casa varchar(100), @tertstorno varchar(20), @tipdoc varchar(2)

	SELECT
		--date pt identificare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@factura=ISNULL(@parXML.value('(/row/@factura)[1]', 'varchar(20)'), ''),
		@idPozDoc=ISNULL(@parXML.value('(/row/@idPozDoc)[1]', 'INT'), ''),
		@lm=ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(13)'), ''),
		@idantetbon=ISNULL(@parXML.value('(/row/@idantetbon)[1]', 'int'), 0)
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identificare utilizator pe baza sesiunii
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati    
	
	if isnull(@idantetbon,0)>0--daca se doreste stornare bon(dinspre macheta de bonuri)
	begin
		--identific documentul care trebuie stornat
		select top 1 
			@numar= bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)'),
			@data=Data_bon,
			@tip=bon.value('(/date/document/@tipdoc)[1]','varchar(2)'),
			@numarBon=numar_bon,
			@casa=casa_de_marcat
		from antetBonuri where IdAntetBon=@idantetbon

		set @tipDoc=@tip
	end
	
	select @tip=(case when @tip in ('RC','RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)

	IF @numar=''
	BEGIN
		SELECT 'Selectati mai intai documentul pentru stornare!' AS textMesaj FOR XML RAW, ROOT('Mesaje')
		RETURN -1
	END  
	
	SELECT @lm AS lm ,@numardoc AS numardoc, CONVERT(CHAR(10),@data,101) AS dataFactDoc, @tipDoc tipdoc,
		@numar as numar, @tip as tip, CONVERT(CHAR(10),@data,101) as data, @idantetbon idantetbon, @numarBon numarBon, @casa casa
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
		SET idPozDoc = pd.idPozDoc,	cantitate_storno=cantitate_storno-isnull(c.cant_stornata,0)
			,cantitate_stornoMax=cantitate_stornoMax-isnull(c.cant_stornata,0)
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
			AND #pozitiiDoc.pvanzare = convert(decimal(17,5),pd.Pret_vanzare)
			
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