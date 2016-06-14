IF exists (SELECT * FROM sysobjects WHERE name ='wOPStornareDocumentSP ')
	DROP PROCEDURE wOPStornareDocumentSP 
GO
--***
CREATE PROCEDURE wOPStornareDocumentSP @sesiune VARCHAR(50), @parXML xml OUTPUT
AS
set transaction isolation level read uncommitted

DECLARE /*date de identIFicare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(20), @lm VARCHAR(13),
		/*parametri pt generare document nou:*/ @numarDoc VARCHAR(20),@dataDoc DATETIME,@dataFactDoc DATETIME,@idPlajaDoc INT,
		/*alte variabile necesare:*/@utilizator VARCHAR(20), @input XML,@eroare VARCHAR(250),@iDoc INT,@ddoc int,@tipdoc VARCHAR(2),@facturaDoc VARCHAR(20),@NrAvizeUnitar int, @fara_mesaje int,
		/*stornare din bon*/ @idantetbon int, @tert varchar(20)
BEGIN try
	SELECT
		--date pt identIFicare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/*/@tip)[1]', 'VARCHAR(2)'), '')
		,@data=ISNULL(@parXML.value('(/*/@data)[1]', 'DATETIME'), '')
		,@numar=ISNULL(@parXML.value('(/*/@numar)[1]', 'VARCHAR(20)'), '')
		,@idPlajaDoc=ISNULL(@parXML.value('(/*/@idPlajaDoc)[1]', 'INT'), 0)
		,@lm=ISNULL(@parXML.value('(/*/@lm)[1]', 'VARCHAR(13)'), '')
		,@fara_mesaje = ISNULL(@parXML.value('(/*/@fara_mesaje)[1]', 'int'), 0)
				
		--date necesare pt. generare document storno
		,@dataDoc=ISNULL(@parXML.value('(/*/@datadoc)[1]', 'DATETIME'), '')
		,@numarDoc=ISNULL(@parXML.value('(/*/@numardoc)[1]', 'VARCHAR(20)'), '')
		,@facturaDoc=ISNULL(@parXML.value('(/*/@facturadoc)[1]', 'VARCHAR(20)'), '')
		,@dataFactDoc=@parXML.value('(/*/@dataFactDoc)[1]', 'DATETIME')
		
		--date stornare din bon
		,@idantetbon=ISNULL(@parXML.value('(/*/@idantetbon)[1]', 'int'), 0)
		,@tert=ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(20)'),'')
		,@tipdoc=ISNULL(@parXML.value('(/*/@tipdoc)[1]', 'varchar(2)'),'')

	if @idantetbon>0 and isnull(@tert,'')=''--daca nu se culege tert la stornare bon, returnez eroare
		raiserror('Tertul nu este completat! Completati tertul care va fi folosit la intocmirea facturii de stornare!',16,1)
	
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati   
	EXEC luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar OUTPUT, 0, '' 
      
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identIFicare utilizator pe baza sesiunii

	if isnull(@tipdoc,'')<>''--daca se forteaza un anumit tip,
		set @tip=@tipdoc

	select @tip=(case when @tip in ('RC','RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)
	
	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPozitiiDocument') IS NOT NULL
		DROP TABLE #xmlPozitiiDocument
	
	SELECT subunitate,tip,data,numar,numar_pozitie,ISNULL(idPozDoc,0) AS idPozDoc,cantitate_storno,cantitate_stornoMax,cantitate
	INTo #xmlPozitiiDocument
	FROM OPENXML(@iDoc, '/*/DateGrid/row')
	WITH
	(
		cantitate_storno FLOAT '@cantitate_storno'
		,cantitate_stornoMax FLOAT '@cantitate_stornoMax'--cantitatea maxima care poate fi stornata
		,cantitate FLOAT '@cantitate'
		,subunitate VARCHAR(13) '@subunitate'
		,tip VARCHAR(2) '@tip'
		,data DATETIME '@data'
		,numar VARCHAR(20) '@numar'
		,numar_pozitie INT '@numar_pozitie'
		,idPozDoc INT '@idPozDoc'
	)
	EXEC sp_xml_removedocument @iDoc 	
	
	ALTER TABLE #xmlPozitiiDocument add idLinie int identity

	IF EXISTS (SELECT 1 FROM #xmlPozitiiDocument WHERE ABS(cantitate_storno)>ABS(cantitate_stornoMax))	
		RAISERROR('Nu se pot storna cantitati mai mari decat cantitatile de pe documentul initial!',11,1)	
		
	IF NOT EXISTS (SELECT 1 FROM #xmlPozitiiDocument WHERE ABS(cantitate_storno)>0)	
		RAISERROR('Nu exista cantitate de stornat!',11,1)	  

	-- apelare procedura specifica daca aceasta exista, pentru divere validari
	IF EXISTS (SELECT 1 FROM sysobjects where [type]='P' AND [name]='wOPStornareDocumentSPIni')
	BEGIN 
		EXEC wOPStornareDocumentSPIni @sesiune=@sesiune, @parXML=@parXML
	END
	
	BEGIN TRANSACTION StornareDoc
		SET @input=
		(SELECT RTRIM(d.Subunitate) AS '@subunitate', 
			case when d.tip='AC' and isnull(@idantetbon,0)>0 then 'AP' else d.tip end AS '@tip', --daca se face stornare dinspre bonuri, pentru AC se va genera AP de storno
			RTRIM(@numarDoc) AS '@numar',RTRIM(d.Cod_gestiune) AS '@gestiune'
			,CONVERT(VARCHAR(10),@datadoc,101) AS '@data' 
			,RTRIM(case when @idantetbon>0 and d.tip='AC' then @tert else d.Cod_tert end) AS '@tert', --daca se face stornare dinspre bonuri, pe documentul storno se va pune tertul completat
			/*RTRIM(d.factura) AS '@factura',*/RTRIM(d.Contractul) AS '@contract'
			,d.Loc_munca AS '@lm', RTRIM(d.Gestiune_primitoare) AS '@gestprim', 
			/*Nu trimit nimic ca si data facturii. Poate se prinde el.*/
			--CONVERT(VARCHAR(10),ISNULL(@dataFactDoc,d.data_facturii),101) AS '@datafacturii',
			CONVERT(VARCHAR(10),@datadoc,101) AS '@datascadentei',8 AS '@stare'
			,1 AS '@returneaza_inserate' --/*SP
			,d.detalii AS 'detalii' --SP*/
			
			--date pentru pozitiile de document
			,(SELECT RTRIM(p.cod) AS '@cod',RTRIM(p.gestiune) AS '@gestiune',CONVERT(DECIMAL(17,5),x.cantitate_storno) AS '@cantitate'
				,CONVERT(DECIMAL(17,5),p.pret_valuta) AS '@pvaluta', CONVERT(DECIMAL(17,5),p.Pret_de_stoc) AS '@pstoc'
				,CONVERT(DECIMAL(17,5),p.Pret_cu_amanuntul) AS '@pamanunt'--,CONVERT(DECIMAL(17,5),p.TVA_deductibil*(-1)) AS '@sumatva'
				
				,CONVERT(DECIMAL(17,2),p.Cota_TVA,2) AS '@cotatva',RTRIM(p.Cod_intrare) AS '@codintrare', RTRIM(p.Cont_de_stoc) AS '@contstoc' 
				,RTRIM(p.Cont_corespondent) AS '@contcorespondent', CONVERT(DECIMAL(17,2),p.TVA_neexigibil,2) AS '@tvaneexigibil',RTRIM(p.Locatie) AS '@locatie'
				,CONVERT(char(10),p.Data_expirarii,101) AS '@dataexpirarii',RTRIM(p.Loc_de_munca) AS '@lm',LEFT(p.Comanda,20) AS '@comanda'
				,RIGHT(p.Comanda,20) AS '@indbug',RTRIM(p.Barcod) AS '@barcod', RTRIM(p.Cont_intermediar) AS '@contintermediar'
				,RTRIM(p.Cont_venituri) AS '@contvenituri',ROUND(p.Discount,2) AS '@discount'
				,RTRIM(case when @idantetbon>0 and p.tip='AC' then @tert else p.Tert end) AS '@tert'
				,CASE WHEN ISNULL(@facturaDoc,'')='' THEN null else @facturaDoc END AS '@factura'
				,RTRIM(p.Gestiune_primitoare) AS '@gestprim',8 AS '@stare',RTRIM(p.Cont_factura) AS '@contfactura', RTRIM(p.Valuta) AS '@valuta'
				,CONVERT(DECIMAL(17,5),p.Curs) AS '@curs',/*CONVERT(DECIMAL(17,2),p.Accize_cumparare,2)*(-1) AS '@accizecump',*/RTRIM(p.Contract) AS '@contract'
				,RTRIM(p.Jurnal) AS '@jurnal',
				(CASE WHEN @tip in ('TE','DF','PF') THEN ISNULL(NULLIF(RTRIM(p.Grupa),''),rtrim(p.cod_intrare)) else '' END) AS '@codiprimitor' -- '@codiPrim'
				,RTRIM(p.Colet) AS '@colet'
				,rtrim(case when p.tip in ('AP', 'AS', 'AC') then substring(p.numar_DVI, 14, 5) else '' end) as '@punctlivrare'
				,CONVERT(DECIMAL(12), p.Procent_vama) as '@tiptva'
				,idLinie '@idlinie',1 AS '@returneaza_inserate'	--/*SP
				,p.detalii AS 'detalii' --SP*/		
			FROM pozdoc p 
				inner join #xmlPozitiiDocument x on x.idPozdoc=p.idPozdoc and abs(x.cantitate_storno)>0.001	
			WHERE p.Subunitate=d.Subunitate AND p.tip=d.Tip AND p.data=d.Data AND p.Numar=d.Numar
			FOR XML PATH, TYPE)
		FROM doc d	
		WHERE d.Subunitate=@sub AND d.Tip=@tip AND d.Data=@data AND d.Numar=@numar
		FOR XML PATH, type)
		
		/*	Apelare wScriuPozdocSP (daca exista, pentru prelucrari in parXML), wScriuDoc sau wScriuDocBeta.	*/
		IF EXISTS (SELECT 1 FROM sysobjects WHERE [type]='P' and [name]='wScriuPozdocSP')
			EXEC wScriuPozdocSP @sesiune=@sesiune, @parXML=@input OUTPUT
		IF EXISTS (SELECT * FROM sysobjects WHERE name ='wScriuDoc')
			EXEC wScriuDoc @sesiune=@sesiune, @parXML=@input OUTPUT
		ELSE 
			IF EXISTS (SELECT * FROM sysobjects WHERE name ='wScriuDocBeta')
				EXEC wScriuDocBeta @sesiune=@sesiune, @parXML=@input OUTPUT
		--EXEC wScriuPozdoc @sesiune, @input OUTPUT
		
		--citire numar/data document generate prin "wScriuDoc".
		SELECT	@numarDoc=ISNULL(@input.value('(/row/@numar)[1]', 'VARCHAR(20)'), ''),
				@dataDoc=ISNULL(@input.value('(/row/@data)[1]', 'DATETIME'), '')

		--daca s-a returnat idPozDoc al pozitiilor storno, se intretine tabela de legaturiStornare
		EXEC sp_xml_preparedocument @ddoc OUTPUT, @input
		IF OBJECT_ID('tempdb..#xmlPozitiiReturnate') IS NOT NULL
			DROP TABLE #xmlPozitiiReturnate

		SELECT
			r.idlinie, x.idPozdoc as idPozdocInit, r.idPozDoc idPozdocStorno
		INTO #xmlPozitiiReturnate
		FROM OPENXML(@ddoc, '/row/docInserate/row')
		WITH
		(
			idLinie int '@idlinie',
			idPozDoc	int '@idPozDoc'
		) r
		INNER JOIN #xmlPozitiiDocument x on x.idlinie=r.idlinie
	
		IF EXISTS (SELECT * FROM sys.objects WHERE NAME = 'LegaturiStornare 'AND type = 'U') AND EXISTS (SELECT 1 FROM #xmlPozitiiReturnate)
		BEGIN	
			INSERT INTO LegaturiStornare 
			SELECT	r.idPozdocInit, r.idPozDocStorno
			FROM #xmlPozitiiReturnate r
		END

		EXEC sp_xml_removedocument @ddoc
		--select * from legaturicontracte

		--daca documentul initial are legaturi cu contract/comanda pe structuri noi, legam si documentul storno de contractul/comanda respectiva
		INSERT INTO legaturicontracte (idJurnal,idPozContract,idPozdoc,idPozContractCorespondent)
		SELECT null,idPozContract,s.idPozDocStorno,idPozContractCorespondent
		FROM legaturicontracte lc
		INNER JOIN #xmlPozitiiReturnate s ON s.idPozdocInit=lc.idPozdoc

	-->	generare inregistrari contabile
		EXEC faInregistrariContabile @dinTabela=0, @Subunitate=@sub, @Tip=@tip, @Numar=@numarDoc, @Data=@datadoc
	
	COMMIT TRANSACTION StornareDoc
			
	-- apelare procedura specifica daca aceasta exista, pentru listare formular, generare iB storno in cazul bonurilor...etc
	IF EXISTS (SELECT 1 FROM sysobjects where [type]='P' AND [name]='wOPStornareDocumentSP1')
	BEGIN 
		EXEC wOPStornareDocumentSP1 @sesiune=@sesiune, @parXML=@input
	END
	--> daca s-a generat document storno => afisam mesaj de finalizare operatie cu succes
	--> daca operatia se apeleaza indirect (prin alte operatii sau scripturi), sa se permita verificarea variabilei @fara_mesaje, pentru a nu afisa mesajul de mai jos.	
	IF @fara_mesaje = 0
	BEGIN
		SELECT 'S-a generat cu succes documentul storno '+RTRIM(@numarDoc)+' din data de '+LTRIM(CONVERT(VARCHAR(20),@dataDoc,103)) AS textMesaj for xml raw, root('Mesaje')
	END

	BEGIN TRY 
		IF OBJECT_ID('#xmlPozitiiDocument') is not null
			DROP TABLE #xmlPozitiiDocument
		IF OBJECT_ID('#xmlPozitiiReturnate') is not null
			DROP TABLE #xmlPozitiiReturnate
	END TRY 
	BEGIN CATCH END CATCH   
END TRY 
BEGIN CATCH 
	IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'StornareDoc')            
		ROLLBACK TRAN StornareDoc
	SET @eroare='(wOPStornareDocumentSP): '+ERROR_MESSAGE() 
	RAISERROR(@eroare, 16, 1)
END CATCH 
