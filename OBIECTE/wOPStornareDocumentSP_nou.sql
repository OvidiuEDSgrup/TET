IF exists (SELECT * FROM sysobjects WHERE name ='wOPStornareDocumentSP ')
DROP PROCEDURE wOPStornareDocumentSP 
GO
--***
CREATE PROCEDURE wOPStornareDocumentSP @sesiune VARCHAR(50), @parXML xml OUTPUT
AS
set transaction isolation level read uncommitted

-- apelare procedura specIFica daca aceASta exista.
--IF EXISTS (SELECT 1 FROM sysobjects where [type]='P' AND [name]='wOPStornareDocumentSP')
--BEGIN 
--	DECLARE @returnValue INT -- variabila salveaza return value de la procedura specIFica
--	EXEC @returnValue = wOPStornareDocumentSP @sesiune, @parXML OUTPUT
--	RETURN @returnValue
--END
--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
DECLARE /*date de identIFicare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(13),
	@lm VARCHAR(13),
	
	/*parametri pt generare document nou:*/ @numarDoc VARCHAR(13),@dataDoc DATETIME,@dataFactDoc DATETIME,@idPlajaDoc INT,
	
	/*alte variabile necesare:*/@utilizator VARCHAR(20), @input XML,@eroare VARCHAR(250),@iDoc INT,@tipdoc VARCHAR(2),@facturaDoc VARCHAR(20),@NrAvizeUnitar int
BEGIN try
	SELECT
		--date pt identIFicare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/*/@tip)[1]', 'VARCHAR(2)'), '')
		,@data=ISNULL(@parXML.value('(/*/@data)[1]', 'DATETIME'), '')
		,@numar=ISNULL(@parXML.value('(/*/@numar)[1]', 'VARCHAR(13)'), '')
		,@idPlajaDoc=ISNULL(@parXML.value('(/*/@idPlajaDoc)[1]', 'INT'), 0)
		,@lm=ISNULL(@parXML.value('(/*/@lm)[1]', 'VARCHAR(13)'), '')
				
		--date necesare pt. generare document storno
		,@dataDoc=ISNULL(@parXML.value('(/*/@datadoc)[1]', 'DATETIME'), '')
		,@numarDoc=ISNULL(@parXML.value('(/*/@numardoc)[1]', 'VARCHAR(13)'), '')
		,@facturaDoc=ISNULL(@parXML.value('(/*/@facturadoc)[1]', 'VARCHAR(20)'), '')
		,@dataFactDoc=@parXML.value('(/*/@dataFactDoc)[1]', 'DATETIME')

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati   
	EXEC luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar OUTPUT, 0, '' 
      
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identIFicare utilizator pe baza sesiunii

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
		,numar VARCHAR(8) '@numar'
		,numar_pozitie INT '@numar_pozitie'
		,idPozDoc INT '@idPozDoc'
	)
	EXEC sp_xml_removedocument @iDoc 	
	
	IF EXISTS (SELECT 1 FROM #xmlPozitiiDocument WHERE ABS(cantitate_storno)>ABS(cantitate_stornoMax))	
		RAISERROR('Nu se pot storna cantitati mai mari decat cantitatile de pe documentul initial!',11,1)	
		
	IF NOT EXISTS (SELECT 1 FROM #xmlPozitiiDocument WHERE  ABS(cantitate_storno)>0)	
		RAISERROR('Nu exista cantitate de stornat!',11,1)	  
	
	BEGIN TRANSACTION StornareDoc	
	if isnull(@numarDoc, '')=''
	begin
	DECLARE @fXML XML, @tipPentruNr VARCHAR(2), @NrDocPrimit VARCHAR(20),@idPlajaPrimit INT, @NumarDocPrimit INT
		set @tipPentruNr=@tip 
		if @NrAvizeUnitar=1 and @tip='AS' 
			set @tipPentruNr='AP'--/*SP 
		if ISNULL(@parXML.value('(/*/@aviznefacturat)[1]', 'bit'), 0)=1
			set @tipPentruNr='AN' --SP*/
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
		
		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output,@idPlaja=@idPlajaPrimit output
		
		if @NrDocPrimit is null
			raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
		
		set @numarDoc=@NrDocPrimit
	end
		
	DECLARE @fetch_crzPozStornari INT, @numar_pozitie_c INT, @idPozdoc_init_c INT
		,@cantitate_storno_c FLOAT, @cantitate_c FLOAT,	@idPozDocStorno INT
	
	IF OBJECT_ID('tempdb..#xmlPozitiiDocumentStorno') IS NOT NULL
		DROP TABLE #xmlPozitiiDocumentStorno
		
	--DECLARE crzPozStornari CURSOR FOR
	SELECT numar_pozitie,ISNULL(idPozDoc,0) AS idPozDoc,cantitate_storno,cantitate
	INTO #xmlPozitiiDocumentStorno
	FROM #xmlPozitiiDocument
	where abs(cantitate_storno)>0.001	

	--OPEN crzPozStornari
	--fetch next FROM crzPozStornari INTO @numar_pozitie_c,@idPozdoc_init_c, @cantitate_storno_c, @cantitate_c
	--SET @fetch_crzPozStornari=@@FETCH_STATUS
	 
	--while @@FETCH_STATUS=0
	BEGIN
		SET @input=
		(SELECT RTRIM(d.Subunitate) AS '@subunitate', d.tip AS '@tip', RTRIM(@numarDoc) AS '@numar',RTRIM(d.Cod_gestiune) AS '@gestiune'
			,CONVERT(VARCHAR(10),@datadoc,101) AS '@data', RTRIM(d.Cod_tert) AS '@tert', /*RTRIM(d.factura) AS '@factura',*/RTRIM(d.Contractul) AS '@contract'
			,d.Loc_munca AS '@lm', RTRIM(d.Gestiune_primitoare) AS '@gestprim', 
			/*Nu trimit nimic ca si data facturii. Poate se prinde el.*/
			--CONVERT(VARCHAR(10),ISNULL(@dataFactDoc,d.data_facturii),101) AS '@datafacturii',
			CONVERT(VARCHAR(10),@datadoc,101) AS '@datascadentei',8 AS '@stare'
			,1 AS '@returneaza_inserate'
			
			--date pentru pozitiile de document
			,(SELECT RTRIM(p.cod) AS '@cod',RTRIM(p.gestiune) AS '@gestiune',CONVERT(DECIMAL(17,5),x.cantitate_storno) AS '@cantitate'
				,CONVERT(DECIMAL(17,5),p.pret_valuta) AS '@pvaluta', CONVERT(DECIMAL(17,5),p.Pret_de_stoc) AS '@pstoc'
				,CONVERT(DECIMAL(17,5),p.Pret_cu_amanuntul) AS '@pamanunt'--,CONVERT(DECIMAL(17,5),p.TVA_deductibil*(-1)) AS '@sumatva'
				
				,CONVERT(DECIMAL(17,2),p.Cota_TVA,2) AS '@cotatva',RTRIM(p.Cod_intrare) AS '@codintrare', RTRIM(p.Cont_de_stoc) AS '@contstoc' 
				,RTRIM(p.Cont_corespondent) AS '@contcorespondent', CONVERT(DECIMAL(17,2),p.TVA_neexigibil,2) AS '@tvaneexigibil',RTRIM(p.Locatie) AS '@locatie'
				,CONVERT(char(10),p.Data_expirarii,101) AS '@dataexpirarii',RTRIM(p.Loc_de_munca) AS '@lm',LEFT(p.Comanda,20) AS '@comanda'
				,RIGHT(p.Comanda,20) AS '@indbug',RTRIM(p.Barcod) AS '@barcod', RTRIM(p.Cont_intermediar) AS '@contintermediar'
				,RTRIM(p.Cont_venituri) AS '@contvenituri',ROUND(p.Discount,2) AS '@discount', RTRIM(p.Tert) AS '@tert'
				,CASE WHEN ISNULL(@facturaDoc,'')='' THEN null else @facturaDoc END AS '@factura'
				,RTRIM(p.Gestiune_primitoare) AS '@gestprim',8 AS '@stare',RTRIM(p.Cont_factura) AS '@contfactura', RTRIM(p.Valuta) AS '@valuta'
				,CONVERT(DECIMAL(17,5),p.Curs) AS '@curs',/*CONVERT(DECIMAL(17,2),p.Accize_cumparare,2)*(-1) AS '@accizecump',*/RTRIM(p.Contract) AS '@contract'
				,RTRIM(p.Jurnal) AS '@jurnal',(CASE WHEN @tip='TE' THEN RTRIM(p.Grupa) else '' END) AS '@codiprimitor'
				,rtrim(case when p.tip in ('AP', 'AS', 'AC') then substring(p.numar_DVI, 14, 5) else '' end) as '@punctlivrare'
				,CONVERT(DECIMAL(12), p.Procent_vama) as '@tiptva'
				,1 AS '@returneaza_inserate'				
			FROM pozdoc p join #xmlPozitiiDocumentStorno x on x.idPozDoc=p.idPozDoc
			WHERE p.Subunitate=d.Subunitate AND p.tip=d.Tip
				AND p.data=d.Data AND p.Numar=d.Numar
				--AND p.Numar_pozitie=@numar_pozitie_c
				AND abs(x.cantitate_storno)>0.001
			FOR XML PATH, TYPE)
		FROM doc d	
		WHERE d.Subunitate=@sub AND d.Tip=@tip
			AND d.Data=@data AND d.Numar=@numar
		FOR XML PATH, type)
		select 'test', @input
		--EXEC wScriuPozdoc @sesiune,@input OUTPUT		
		EXEC wScriuDocBeta @sesiune,@input OUTPUT		
		
		--daca s-a returnat idPozDoc al pozitiei storno, se intretine tabela de legaturiStornare
		SELECT @idPozDocStorno=ISNULL(@input.value('(/row/docInserate/row/@idPozDoc)[1]', 'INT'), 0)		
		
		IF EXISTS (	SELECT *FROM sys.objects WHERE NAME = 'LegaturiStornare 'AND type = 'U'	) AND @idPozDocStorno<>0
		BEGIN	
			insert into LegaturiStornare 
			select 	@idPozdoc_init_c,@idPozDocStorno	
		END
		
		--select * from legaturicontracte

		--daca documentul initial are legaturi cu contract/comanda pe structuri noi, legam si documentul storno de contractul/comanda respectiva
		insert into legaturicontracte(idJurnal,idPozContract,idPozdoc,idPozContractCorespondent)
		select null,idPozContract,@idPozDocStorno,idPozContractCorespondent
		from legaturicontracte
		where idPozDoc=@idPozdoc_init_c
		
		--select * from legaturicontracte
		
		--FETCH NEXT FROM crzPozStornari INTO @numar_pozitie_c,@idPozdoc_init_c, @cantitate_storno_c, @cantitate_c
	END
	
	COMMIT TRANSACTION StornareDoc
	--formare XML pentru apelare wScriuPozdoc    						
	/*SET @input=
		(SELECT RTRIM(d.Subunitate) AS '@subunitate', d.tip AS '@tip', RTRIM(@numarDoc) AS '@numar',RTRIM(d.Cod_gestiune) AS '@gestiune',
			CONVERT(VARCHAR(10),@datadoc,101) AS '@data', RTRIM(d.Cod_tert) AS '@tert', RTRIM(d.factura) AS '@factura',RTRIM(d.Contractul) AS '@contract',
			d.Loc_munca AS '@lm', RTRIM(d.Gestiune_primitoare) AS '@gestprim', CONVERT(VARCHAR(10),d.data_facturii,101) AS '@datafacturii',
			CONVERT(VARCHAR(10),d.data_scadentei,101) AS '@datAScadentei',8 AS '@stare',
			
			--date pentru pozitiile de document
			(SELECT RTRIM(p.cod) AS '@cod',RTRIM(p.gestiune) AS '@gestiune',CONVERT(DECIMAL(17,5),x.cantitate_storno) AS '@cantitate', 
				CONVERT(DECIMAL(17,5),p.pret_valuta) AS '@pvaluta', CONVERT(DECIMAL(17,5),p.Pret_de_stoc) AS '@pstoc',-- p.adaos AS'@adaos',
				CONVERT(DECIMAL(17,5),p.Pret_cu_amanuntul) AS '@pamanunt',CONVERT(DECIMAL(17,5),p.TVA_deductibil*(-1)) AS '@sumatva',
				
				CONVERT(DECIMAL(17,2),p.Cota_TVA,2) AS '@cotatva',RTRIM(p.Cod_INTrare) AS '@codINTrare', RTRIM(p.Cont_de_stoc) AS '@contstoc', 
				RTRIM(p.Cont_corespondent) AS '@contcorespondent', CONVERT(DECIMAL(17,2),p.TVA_neexigibil,2) AS '@tvaneexigibil',RTRIM(p.Locatie) AS '@locatie',
				CONVERT(char(10),p.Data_expirarii,101) AS '@dataexpirarii',RTRIM(p.Loc_de_munca) AS '@lm',LEFT(p.ComANDa,20) AS '@comANDa',
				RIGHT(p.ComANDa,20) AS '@indbug',RTRIM(p.Barcod) AS '@barcod', RTRIM(p.Cont_INTermediar) AS '@contINTermediar',
				RTRIM(p.Cont_venituri) AS '@contvenituri',ROUND(p.Discount,2) AS '@discount', RTRIM(p.Tert) AS '@tert',
				CASE WHEN ISNULL(@facturaDoc,'')='' THEN RTRIM(p.Factura) else @facturaDoc END AS '@factura',
				RTRIM(p.Gestiune_primitoare) AS '@gestprim',8 AS '@stare',RTRIM(p.Cont_factura) AS '@contfactura', RTRIM(p.Valuta) AS '@valuta',
				CONVERT(DECIMAL(17,5),p.Curs) AS '@curs',CONVERT(DECIMAL(17,2),p.Accize_cumparare,2)*(-1) AS '@accizecump',RTRIM(p.Contract) AS '@contract', 
				RTRIM(p.Jurnal) AS '@jurnal',CASE WHEN @tip='TE' THEN RTRIM(p.Grupa) else '' END AS '@codiPrim',
				CONVERT(decimal(12), p.Procent_vama) as '@tiptva'
				1 AS '@returneaza_inserate', ISNULL(x.idPozDoc,0) AS '@idPozDoc_init'	
				
				FROM pozdoc p 
					inner join #xmlPozitiiDocument x on x.subunitate=p.Subunitate AND x.tip=p.Tip  
						AND x.data=p.Data AND x.numar=p.numar AND x.numar_pozitie=p.Numar_pozitie AND x.cantitate_storno<0
				where p.Subunitate=d.Subunitate AND p.tip=d.Tip
					AND p.data=d.Data AND p.Numar=d.Numar
			for xml PATH, TYPE)
		FROM doc d	
		where d.Subunitate=@sub AND d.Tip=@tip
			AND d.Data=@data AND d.Numar=@numar
		for XML PATH, type)
		
	--SELECT CONVERT(VARCHAR(max),@input)
	exec wScriuPozdoc @sesiune,@input output
	*/	
	
			
	/*update p SET stare='4' 
	FROM pozdoc p 
		inner join #xmlPozitiiDocument x on p.Subunitate=x.subunitate AND p.tip=x.tip 
			AND p.Numar=p.Numar AND p.data=x.data AND p.Numar_pozitie=x.numar_pozitie
			AND x.Cantitate_storno<0
	where p.Subunitate=@sub AND p.tip=@tip AND p.numar=@numar AND p.data=@data
	*/
		
	-->daca s-a generat document storno => afisam mesaj de finalizare operatie cu succes	
	
	SELECT 'S-a generat cu succes documentul storno '+RTRIM(@numarDoc)+' din data de  '+LTRIM(CONVERT(VARCHAR(20),@dataDoc,103)) AS textMesaj for xml raw, root('Mesaje') 
	BEGIN TRY 
		IF OBJECT_ID('#xmlPozitiiDocument') is not null
			DROP TABLE #xmlPozitiiDocument
	END TRY 
	BEGIN CATCH END CATCH   
END TRY 
BEGIN CATCH 
	IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'StornareDoc')            
		ROLLBACK TRAN StornareDoc
	SET @eroare='(wOPStornareDocumentSP): '+ERROR_MESSAGE() 
	RAISERROR(@eroare, 16, 1)
END CATCH 
