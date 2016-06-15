--***
CREATE PROCEDURE yso_wOPGolireGestPrinTEStorno @sesiune VARCHAR(50), @parXML xml 
AS

DECLARE /*date de identIFicare document:*/
	@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(13),@lm VARCHAR(13),
	
	/*parametri pt generare document nou:*/ 
	@numarDoc VARCHAR(13),@dataDoc DATETIME,@dataFactDoc DATETIME,@idPlajaDoc INT,
	
	/*alte variabile necesare:*/
	@utilizator VARCHAR(20), @input XML,@eroare VARCHAR(250),@iDoc INT,@tipdoc VARCHAR(2),@facturaDoc VARCHAR(20)
	, @gestiune varchar(20), @gestprim varchar(20)
BEGIN try

--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/

	set transaction isolation level read uncommitted
	SELECT
		--date pt identIFicare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'VARCHAR(2)'), 'TE')
		,@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'DATETIME'), '')
		,@numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'VARCHAR(13)'), '')
		,@idPlajaDoc=ISNULL(@parXML.value('(/parametri/@idPlajaDoc)[1]', 'INT'), 0)
				
		--date necesare pt. generare document storno
		,@dataDoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'DATETIME'), '')
		,@numarDoc=ISNULL(@parXML.value('(/parametri/@numardoc)[1]', 'VARCHAR(13)'), '')
		,@facturaDoc=ISNULL(@parXML.value('(/parametri/@facturadoc)[1]', 'VARCHAR(20)'), '')
		,@dataFactDoc=@parXML.value('(/parametri/@dataFactDoc)[1]', 'DATETIME')
		,@gestiune=ISNULL(@parXML.value('(/parametri/@gestiune)[1]', 'varchar(20)'),'' )
		,@gestprim=ISNULL(@parXML.value('(/parametri/@gestprim)[1]', 'varchar(20)'), '700')

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati       
  
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identIFicare utilizator pe baza sesiunii
		
	--numarul sugerat se introduce in tabela de numere de documente rezervate
	IF ISNULL(@numarDoc,'')=''
	BEGIN	
		DECLARE @fXML XML, @tipPentruNr VARCHAR(2), @NrDocPrimit VARCHAR(20),@idPlajaPrimit INT, @NumarDocPrimit INT
		SET @tipPentruNr=@tip 
		
		SET @tipPentruNr='TE' 
		SET @fXML = '<row/>'
		SET @fXML.modify  ('insert attribute tipmacheta {"DO"} into (/row)[1]')
		SET @fXML.modify  ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		SET @fXML.modify  ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		SET @fXML.modify  ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
		
		EXEC wIauNrDocFiscaleSP @parXML=@fXML, @NrDoc=@NrDocPrimit OUTPUT, @Numar=@NumarDocPrimit OUTPUT, @idPlaja=@idPlajaPrimit OUTPUT

		SET @numardoc=@NrDocPrimit			
	END

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPozitiiDocument') IS NOT NULL
		DROP TABLE #xmlPozitiiDocument
	
	SELECT *
	INTo #xmlPozitiiDocument
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(	gestiune varchar(10) '@gestiune'
		,cod varchar(20) '@cod'
		,codintrare varchar(20) '@codintrare'
		,lm varchar(20) '@lm'
		,contract varchar(20) '@contract'
		,comanda varchar(20) '@comanda'
		,cant_disponibila FLOAT '@cant_disponibila'
		,cant_storno FLOAT '@cant_storno'--cantitatea maxima care poate fi stornata
		,pamanunt FLOAT '@pamanunt'
		,numar_pozitie INT '@numar_pozitie'
		,idPozDoc INT '@idpozdoc'
	)
	EXEC sp_xml_removedocument @iDoc 	
	
	IF EXISTS (SELECT 1 FROM #xmlPozitiiDocument WHERE ABS(cant_storno)>ABS(cant_disponibila))
		RAISERROR('Nu se pot storna cantitati mai mari decat cantitatile de pe documentul initial!',11,1)	  
		
	DECLARE @fetch_crzPozStornari INT, @numar_pozitie_c INT, @idPozdoc_init_c INT
		,@cantitate_storno_c FLOAT, @cantitate_c FLOAT,	@idPozDocStorno INT
	
	--BEGIN TRANSACTION --yso_wOPGolireGestPrinTEStorno
	if @sesiune='' select * from #xmlPozitiiDocument 
	SET @input=
	(SELECT '1' '@subunitate', 'TE' AS '@tip', @numarDoc AS '@numar',@gestiune AS '@gestiune'
		,CONVERT(VARCHAR(10),@datadoc,101) AS '@data'
		,@gestprim AS '@gestprim'
		,8 AS '@stare'
		
		--/*date pentru pozitiile de document
		,(SELECT RTRIM(isnull(x.cod,p.cod)) AS '@cod',@gestiune AS '@gestiune'
			,CONVERT(DECIMAL(17,5),x.cant_storno*(-1)) AS '@cantitate'
			,CONVERT(DECIMAL(17,5),isnull(x.pamanunt,p.Pret_cu_amanuntul)) AS '@pamanunt'
			,rtrim(ISNULL(p.Accize_cumparare,1)) as '@categpret'
			,RTRIM(isnull(x.codintrare,p.Cod_intrare)) AS '@codintrare'
			,RTRIM(isnull(x.lm,p.Loc_de_munca)) AS '@lm'
			,LEFT(isnull(x.comanda,p.Comanda),20) AS '@comanda'
			,RTRIM(isnull(x.contract,p.Contract)) AS '@factura'
			--,RTRIM(isnull(x.locatie,p.Locatie)) AS '@locatie'
			,RTRIM(p.Gestiune_primitoare) AS '@gestprim'
			,8 AS '@stare'
			,RTRIM(isnull(x.codintrare,p.Grupa)) AS '@codiPrim'	
		FROM pozdoc p inner join #xmlPozitiiDocument x on x.idpozdoc=p.idPozDoc
		WHERE x.cant_storno>=0.001 --*/,(select '1' test 
		FOR XML PATH, TYPE)
	FOR XML PATH, type)
		
	if @sesiune='' select @input
	EXEC wScriuPozdoc @sesiune,@input OUTPUT		
		
	--daca s-a returnat idPozDoc al pozitiei storno,
	-->daca s-a generat document storno => afisam mesaj de finalizare operatie cu succes	
	SELECT @idPozDocStorno=ISNULL(@input.value('(/row/@idPozDoc)[1]', 'INT'), 0)		
	if @idPozDocStorno<>0 and isnull(@numarDoc,'')=''
		select @numarDoc=p.Numar from pozdoc p where p.Subunitate='1' and p.Tip='TE' and p.idPozDoc=@idPozDocStorno
	if ISNULL(@numardoc,'')<>''
		SELECT 'S-a generat cu succes documentul storno '+RTRIM(@numarDoc)
			+' din data de  '+LTRIM(CONVERT(VARCHAR(20),@dataDoc,103)) AS textMesaj for xml raw, root('Mesaje') 
	--/*sp
--	ROLLBACK
----sp*/COMMIT 
--	TRANSACTION --yso_wOPGolireGestPrinTEStorno
	
	BEGIN TRY 
		IF OBJECT_ID('#xmlPozitiiDocument') is not null
			DROP TABLE #xmlPozitiiDocument
	END TRY 
	BEGIN CATCH END CATCH   
END TRY 
BEGIN CATCH 
	if @NumarDocPrimit is not null and not exists(select 1 from docfiscalerezervate where idPlaja=@idPlajaPrimit)
		insert into docfiscalerezervate(idPlaja,numar,expirala) 
		values (@idPlajaPrimit,@NumarDocPrimit,DATEADD(mi, 15, GETDATE()))
	--IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'yso_wOPGolireGestPrinTEStorno')            
	--	ROLLBACK TRAN --yso_wOPGolireGestPrinTEStorno
	SET @eroare='(yso_wOPGolireGestPrinTEStorno): '+ERROR_MESSAGE() 
	RAISERROR(@eroare, 16, 1)
END CATCH 
