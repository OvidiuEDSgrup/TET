IF exists (SELECT * FROM sysobjects WHERE name ='wOPStornareDocumentSP ')
DROP PROCEDURE wOPStornareDocumentSP 
GO
--***
CREATE PROCEDURE wOPStornareDocumentSP @sesiune VARCHAR(50), @parXML xml OUTPUT 
AS

DECLARE /*date de identIFicare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(13),
	@lm VARCHAR(13),
	
	/*parametri pt generare document nou:*/ @numarDoc VARCHAR(13),@dataDoc DATETIME,@dataFactDoc DATETIME,@idPlajaDoc INT,
	
	/*alte variabile necesare:*/@utilizator VARCHAR(20), @input XML,@eroare VARCHAR(250),@iDoc INT,@tipdoc VARCHAR(2),@facturaDoc VARCHAR(20)--/*sp
		,@aviznefacturat bit
	--/*sp
BEGIN try
	SELECT
		--date pt identIFicare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'VARCHAR(2)'), '')
		,@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'DATETIME'), '')
		,@numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'VARCHAR(13)'), '')
		,@idPlajaDoc=ISNULL(@parXML.value('(/parametri/@idPlajaDoc)[1]', 'INT'), 0)
				
		--date necesare pt. generare document storno
		,@dataDoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'DATETIME'), '')
		,@numarDoc=ISNULL(@parXML.value('(/parametri/@numardoc)[1]', 'VARCHAR(13)'), '')
		,@facturaDoc=ISNULL(@parXML.value('(/parametri/@facturadoc)[1]', 'VARCHAR(20)'), '')
		,@dataFactDoc=@parXML.value('(/parametri/@dataFactDoc)[1]', 'DATETIME')--/*sp 
		,@aviznefacturat=ISNULL(@parXML.value('(/*/@aviznefacturat)[1]', 'bit'), 0) --sp*/

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati       
  
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identIFicare utilizator pe baza sesiunii

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPozitiiDocument') IS NOT NULL
		DROP TABLE #xmlPozitiiDocument
	
	SELECT subunitate,tip,data,numar,numar_pozitie,ISNULL(idPozDoc,0) AS idPozDoc,cantitate_storno,cantitate_stornoMax,cantitate
	INTo #xmlPozitiiDocument
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		cantitate_storno FLOAT '@cantitate_storno'
		,cantitate_stornoMax FLOAT '@cantitate_stornoMax'--cantitatea maxima care poate fi stornata
		,cantitate FLOAT '@cantitate'
		,subunitate VARCHAR(13) '@subunitate'
		,tip VARCHAR(2) '@tip'
		,data DATETIME '@data'
		,numar VARCHAR(8) '@numar'
		,numar_pozitie INT '@numar_pozitie'
		,idPozDoc INT '@idPozDoc'
	)
	EXEC sp_xml_removedocument @iDoc 	
	 
	IF /*sp EXISTS (	SELECT *FROM sys.objects WHERE NAME = 'docfiscalerezervate 'AND type = 'U'	)
		AND NOT EXISTS(SELECT 1 FROM docfiscalerezervate WHERE charindex(convert(varchar(8),numar),@numarDoc)>0 /*AND idPlaja=@idPlajaDoc*/)
		 RAISERROR('Numarul de document rezervat pentru aceasta operatie a expirat, va rugam sa reluati operatia!',11,1)
		--sp*/isnull(@numardoc,'')='' --/*sp
	BEGIN
		DECLARE @fXML XML, @tipPentruNr VARCHAR(2), @NrDocPrimit VARCHAR(20),@idPlajaPrimit INT, @NumarDocPrimit INT,@NrAvizeUnitar INT
		EXEC luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar OUTPUT, 0, '' 
		SET @tipPentruNr=@tip 
		
		IF @NrAvizeUnitar=1 AND @tip='AS' 
			SET @tipPentruNr='AP' 
			
		if @aviznefacturat=1
			set @tipPentruNr='AN'
			
		SET @fXML = '<row/>'
		SET @fXML.modify  ('insert attribute tipmacheta {"DO"} into (/row)[1]')
		SET @fXML.modify  ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		SET @fXML.modify  ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		SET @fXML.modify  ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
		
		EXEC wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit OUTPUT, @Numar=@NumarDocPrimit OUTPUT, @idPlaja=@idPlajaPrimit OUTPUT

		SET @numardoc=@NrDocPrimit
	END--sp*/
	
	IF EXISTS (SELECT 1 FROM #xmlPozitiiDocument WHERE ABS(cantitate_storno)>ABS(cantitate_stornoMax))
	
		RAISERROR('Nu se pot storna cantitati mai mari decat cantitatile de pe documentul initial!',11,1)	  

--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
		
	DECLARE @fetch_crzPozStornari INT, @numar_pozitie_c INT, @idPozdoc_init_c INT
		,@cantitate_storno_c FLOAT, @cantitate_c FLOAT,	@idPozDocStorno INT
	
	--BEGIN TRANSACTION StornareDoc
	DECLARE crzPozStornari CURSOR FOR
	SELECT numar_pozitie,ISNULL(idPozDoc,0) AS idPozDoc,cantitate_storno,cantitate
	FROM #xmlPozitiiDocument
	OPEN crzPozStornari
	
	fetch next FROM crzPozStornari INTO @numar_pozitie_c,@idPozdoc_init_c, @cantitate_storno_c, @cantitate_c
	SET @fetch_crzPozStornari=@@FETCH_STATUS
	 
	while @@FETCH_STATUS=0
	BEGIN
		SET @input=
		(SELECT RTRIM(d.Subunitate) AS '@subunitate', d.tip AS '@tip', RTRIM(@numarDoc) AS '@numar',RTRIM(d.Cod_gestiune) AS '@gestiune'
			,CONVERT(VARCHAR(10),@datadoc,101) AS '@data', RTRIM(d.Cod_tert) AS '@tert'
--/*sp
			,RTRIM(CASE @tip WHEN 'TE' THEN d.Contractul ELSE d.factura END) AS '@factura'
			,RTRIM(CASE @tip WHEN 'TE' THEN '' ELSE d.Contractul END) AS '@contract'
			,@aviznefacturat as '@aviznefacturat' 
--sp*/
			,d.Loc_munca AS '@lm', RTRIM(d.Gestiune_primitoare) AS '@gestprim'
			/*Nu trimit nimic ca si data facturii. Poate se prinde el.*/
			,CONVERT(VARCHAR(10),ISNULL(@dataFactDoc,d.data_facturii),101) AS '@datafacturii'
			,CONVERT(VARCHAR(10),d.data_scadentei,101) AS '@datascadentei',8 AS '@stare'
			,1 AS '@returneaza_inserate'
			
			--date pentru pozitiile de document
			,(SELECT RTRIM(p.cod) AS '@cod',RTRIM(p.gestiune) AS '@gestiune',CONVERT(DECIMAL(17,5),@cantitate_storno_c) AS '@cantitate'
				,CONVERT(DECIMAL(17,5),p.pret_valuta) AS '@pvaluta', CONVERT(DECIMAL(17,5),p.Pret_de_stoc) AS '@pstoc'
				,CONVERT(DECIMAL(17,5),p.Pret_cu_amanuntul) AS '@pamanunt',CONVERT(DECIMAL(17,5),p.TVA_deductibil*(-1)) AS '@sumatva'
				
				,CONVERT(DECIMAL(17,2),p.Cota_TVA,2) AS '@cotatva',RTRIM(p.Cod_INTrare) AS '@codintrare', RTRIM(p.Cont_de_stoc) AS '@contstoc' 
				,RTRIM(p.Cont_corespondent) AS '@contcorespondent', CONVERT(DECIMAL(17,2),p.TVA_neexigibil,2) AS '@tvaneexigibil'
				,RTRIM(p.Locatie) AS '@locatie'
				,CONVERT(char(10),p.Data_expirarii,101) AS '@dataexpirarii',RTRIM(p.Loc_de_munca) AS '@lm',LEFT(p.Comanda,20) AS '@comanda'
				,RIGHT(p.Comanda,20) AS '@indbug',RTRIM(p.Barcod) AS '@barcod', RTRIM(p.Cont_intermediar) AS '@contintermediar'
				,RTRIM(p.Cont_venituri) AS '@contvenituri',ROUND(p.Discount,2) AS '@discount', RTRIM(p.Tert) AS '@tert'
				,/*sp*/CASE p.tip WHEN 'TE' THEN p.Factura ELSE /*sp*/
					CASE WHEN ISNULL(@facturaDoc,'')='' THEN RTRIM(p.Factura) else @facturaDoc END END AS '@factura'
				,RTRIM(p.Gestiune_primitoare) AS '@gestprim',8 AS '@stare',RTRIM(p.Cont_factura) AS '@contfactura', RTRIM(p.Valuta) AS '@valuta'
				,CONVERT(DECIMAL(17,5),p.Curs) AS '@curs',/*spCONVERT(DECIMAL(17,2),sp*/p.Accize_cumparare/*sp,2)*(-1)sp*/ AS '@accizecump'
				,RTRIM(p.Contract) AS '@contract'
				,RTRIM(p.Jurnal) AS '@jurnal',CASE WHEN @tip='TE' THEN RTRIM(p.Grupa) else '' END AS '@codiprimitor'	
				,1 AS '@returneaza_inserate'			
				
			FROM pozdoc p 
			WHERE p.Subunitate=d.Subunitate AND p.tip=d.Tip
				AND p.data=d.Data AND p.Numar=d.Numar
				AND p.Numar_pozitie=@numar_pozitie_c
				AND @cantitate_storno_c<>0
			FOR XML PATH, TYPE)
		FROM doc d	
		WHERE d.Subunitate=@sub AND d.Tip=@tip
			AND d.Data=@data AND d.Numar=@numar
		FOR XML PATH, type)
		
		EXEC wScriuPozdoc @sesiune,@input OUTPUT		
		
		--daca s-a returnat idPozDoc al pozitiei storno, se intretine tabela de legaturiStornare
		SELECT @idPozDocStorno=ISNULL(@input.value('(/row/docInserate/row/@idPozDoc)[1]', 'INT'), 0)
		
		IF EXISTS (	SELECT *FROM sys.objects WHERE NAME = 'LegaturiStornare 'AND type = 'U'	) AND @idPozDocStorno<>0
		BEGIN	
			insert into LegaturiStornare 
			select 	@idPozdoc_init_c,@idPozDocStorno	
		END
		
		FETCH NEXT FROM crzPozStornari INTO @numar_pozitie_c,@idPozdoc_init_c, @cantitate_storno_c, @cantitate_c
	END
	
	--COMMIT TRANSACTION StornareDoc	
			
	/*update p SET stare='4' 
	FROM pozdoc p 
		inner join #xmlPozitiiDocument x on p.Subunitate=x.subunitate AND p.tip=x.tip 
			AND p.Numar=p.Numar AND p.data=x.data AND p.Numar_pozitie=x.numar_pozitie
			AND x.Cantitate_storno<0
	where p.Subunitate=@sub AND p.tip=@tip AND p.numar=@numar AND p.data=@data
	*/
		
	--/*sp --daca s-a generat document storno => afisam mesaj de finalizare operatie cu succes	
	if exists (select top 1 1 from pozdoc p where p.idPozDoc=@idPozDocStorno)
		SELECT 'S-a generat cu succes documentul storno '+RTRIM(@numarDoc)+' din data de  '+LTRIM(CONVERT(VARCHAR(20),@dataDoc,103)) AS textMesaj for xml raw, root('Mesaje') 
	ELSE 
		SELECT 'Nu s-a generat documentul storno '+RTRIM(@numarDoc)+' in data de  '+LTRIM(CONVERT(VARCHAR(20),@dataDoc,103)) AS textMesaj for xml raw, root('Mesaje') --sp*/
	BEGIN TRY 
		IF OBJECT_ID('#xmlPozitiiDocument') is not null
			DROP TABLE #xmlPozitiiDocument
	END TRY 
	BEGIN CATCH END CATCH   
	RETURN 0
END TRY 
BEGIN CATCH 
	--IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'StornareDoc')            
	--	ROLLBACK TRAN StornareDoc
	SET @eroare='(wOPStornareDocumentSP): '+ERROR_MESSAGE() 
	RAISERROR(@eroare, 16, 1)
END CATCH 
