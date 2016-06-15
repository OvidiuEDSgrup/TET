--***
CREATE PROCEDURE yso_wOPStornareDocument @sesiune VARCHAR(50), @parXML xml 
AS
set transaction isolation level read uncommitted

DECLARE /*date de identIFicare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(20)
			, @lm VARCHAR(13), @lmStab VARCHAR(13),
		/*parametri pt generare document nou:*/ @numarDoc VARCHAR(20),@dataDoc DATETIME,@dataFactDoc DATETIME,@idPlajaDoc INT,
		/*alte variabile necesare:*/@utilizator VARCHAR(20), @input XML,@eroare VARCHAR(250),@iDoc INT,@ddoc int,@tipdoc VARCHAR(2),@facturaDoc VARCHAR(20)
			,@NrAvizeUnitar int, @fara_mesaje int,
		/*stornare din bon*/ @idantetbon int, @tert varchar(20), @gestiune varchar(20), @cont_casa varchar(20), @faraGenerarePlin int
BEGIN try

--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/

	SELECT
		--date pt identIFicare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'VARCHAR(2)'), '')
		,@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'DATETIME'), '')
		,@numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'VARCHAR(20)'), '')
		,@idPlajaDoc=ISNULL(@parXML.value('(/parametri/@idPlajaDoc)[1]', 'INT'), 0)
		,@lm=ISNULL(@parXML.value('(/parametri/@lm)[1]', 'VARCHAR(13)'), '')
		,@fara_mesaje = ISNULL(@parXML.value('(/parametri/@fara_mesaje)[1]', 'int'), 0)
				
		--date necesare pt. generare document storno
		,@dataDoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'DATETIME'), '')
		,@numarDoc=ISNULL(@parXML.value('(/parametri/@numardoc)[1]', 'VARCHAR(20)'), '')
		,@facturaDoc=ISNULL(@parXML.value('(/parametri/@facturadoc)[1]', 'VARCHAR(20)'), '')
		,@dataFactDoc=@parXML.value('(/parametri/@dataFactDoc)[1]', 'DATETIME')
		
		--date stornare din bon
		,@idantetbon=ISNULL(@parXML.value('(/parametri/@idantetbon)[1]', 'int'), 0)
		,@tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'),'')
		,@tipdoc=ISNULL(@parXML.value('(/parametri/@tipdoc)[1]', 'varchar(2)'),'')
		,@faraGenerarePlin = isnull(@parXML.value('(/*/@faraplin)[1]','int'),0)

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati   
	EXEC luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar OUTPUT, 0, '' 
      
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identIFicare utilizator pe baza sesiunii

	if isnull(@tipdoc,'')<>''--daca se forteaza un anumit tip,
		set @tip=@tipdoc

	select @tip=(case when @tip in ('RC','RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)

	if @idantetbon>0 and @faraGenerarePlin=0
	begin
		if isnull(@tert,'')=''--daca nu se culege tert la stornare bon, returnez eroare
			raiserror('Tertul nu este completat! Completati tertul care va fi folosit la intocmirea facturii de stornare!',16,1)
		
		select 
			@gestiune=dbo.wfProprietateUtilizator('GESTPV',@utilizator),
			@lmStab=dbo.wfProprietateUtilizator('LOCMUNCASTABIL',@utilizator),
			@cont_casa=dbo.wfProprietateUtilizator('CONTCASA',@utilizator)
		
		if isnull(@gestiune,'')=''
			raiserror('Verificati proprietatea GESTPV (gestiune pentru vanzare) a utilizatorului curent!',16,1)
		if isnull(@lmStab,'')=''
			raiserror('Verificati proprietatea LOCMUNCASTABIL (locul de munca) a utilizatorul curent!',16,1)
		if isnull(@cont_casa,'')=''
			raiserror('Verificati proprietatea CONTCASA (contul asociat) a utilizatorul curent!',16,1)
		
		if @faraGenerarePlin=0 and @fara_mesaje=0
			if @parXML.value('(/*/@fara_mesaje)[1]', 'bit') is null
				set @parxml.modify('insert attribute fara_mesaje {"1"} into (/*)[1]')
			else 
				set @parXML.modify('replace value of (/row/@fara_mesaje)[1] with "1"')
	end
	
	IF OBJECT_ID('tempdb..#yso_wOPStornareDocument') is not null
		DROP TABLE #yso_wOPStornareDocument
	
	select parXML=(select idantetbon=@idantetbon, faraplin=@faraGenerarePlin, contcasa=rtrim(@cont_casa) for xml raw, type) 
	into #yso_wOPStornareDocument
	
	BEGIN TRANSACTION yso_wOPStornareDocument
	
	exec wOPStornareDocument @sesiune, @parXML
	
	COMMIT TRANSACTION yso_wOPStornareDocument
	
	BEGIN TRY 
		IF OBJECT_ID('tempdb..#yso_wOPStornareDocument') is not null
			DROP TABLE #yso_wOPStornareDocument
	END TRY 
	BEGIN CATCH END CATCH   
END TRY 
BEGIN CATCH 
	IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'yso_wOPStornareDocument')            
		ROLLBACK TRAN yso_wOPStornareDocument
	SET @eroare='(yso_wOPStornareDocument): '+ERROR_MESSAGE() 
	RAISERROR(@eroare, 16, 1)
END CATCH 
