IF exists (SELECT * FROM sysobjects WHERE name ='yso_wOPStornareDocument')
DROP PROCEDURE yso_wOPStornareDocument 
GO
--***
CREATE PROCEDURE yso_wOPStornareDocument @sesiune VARCHAR(50), @parXML xml OUTPUT
AS
set transaction isolation level read uncommitted

-- apelare procedura specIFica daca aceASta exista.
--IF EXISTS (SELECT 1 FROM sysobjects where [type]='P' AND [name]='yso_wOPStornareDocument')
--BEGIN 
--	DECLARE @returnValue INT -- variabila salveaza return value de la procedura specIFica
--	EXEC @returnValue = yso_wOPStornareDocument @sesiune, @parXML OUTPUT
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

	if @idantetbon>0 and isnull(@tert,'')=''--daca nu se culege tert la stornare bon, returnez eroare
		raiserror('Tertul nu este completat! Completati tertul care va fi folosit la intocmirea facturii de stornare!',16,1)
	
	
	BEGIN TRANSACTION yso_wOPStornareDocument	

	exec wOPStornareDocument @sesiune, @parXML 
	
	COMMIT TRANSACTION yso_wOPStornareDocument
		
	BEGIN TRY 
		IF OBJECT_ID('#xmlPozitiiDocument') is not null
			DROP TABLE #xmlPozitiiDocument
	END TRY 
	BEGIN CATCH END CATCH   
END TRY 
BEGIN CATCH 
	IF EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'yso_wOPStornareDocument')            
		ROLLBACK TRAN yso_wOPStornareDocument
	SET @eroare='(yso_wOPStornareDocument): '+ERROR_MESSAGE() 
	RAISERROR(@eroare, 16, 1)
END CATCH 
