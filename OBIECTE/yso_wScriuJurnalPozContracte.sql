IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'yso_wScriuJurnalPozContracte'
		)
	DROP PROCEDURE yso_wScriuJurnalPozContracte
GO

CREATE PROCEDURE yso_wScriuJurnalPozContracte @sesiune VARCHAR(50), @parXML XML
OUTPUT AS

DECLARE @idContract INT, @data DATETIME, @explicatii VARCHAR(60), @stare VARCHAR(2), @mesaj VARCHAR(500), @detalii XML, @utilizator VARCHAR(100), @rootXml varchar(50),
		@iDoc int, @rootXmlPoz varchar(50), @multiDoc int
declare @contracte table (idContract int, data datetime, explicatii varchar(max), stare int, detalii xml)

BEGIN TRY
	-- se trimite cu root Date cand sunt afectate mai multe contracte
	if @parXML.exist('(/Date)')=1 --Daca exista parametrul Date inseamna ca avem date multiple de introdus in tabela  
	begin  
		set @rootXmlPoz='/Date/row/row'  
		set @rootXml='/Date/row'
		set @multiDoc=1  
	end  
	else  
	begin  
		set @rootXmlPoz='/row/row'  
		set @rootXml='/row'
		set @multiDoc=0  
	end

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	insert into @contracte(idContract, data, explicatii, stare, detalii)
	select idContract, data, explicatii, stare, detalii
	from OPENXML(@iDoc, @rootXml)
		WITH 
		(
			idContract int '@idContract', 
			data datetime '@data',
			explicatii varchar(max) '@explicatii',
			stare int '@stare',
			detalii xml 'detalii/row'
		)
	exec sp_xml_removedocument @iDoc

	/*** Utilizator */
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	/** Daca nu se trimite starea va ramane in starea anterioara **/
	update c
		set stare = stari.stare
	from @contracte c
	cross apply (select top 1 stare 
					FROM JurnalContracte j
					WHERE j.idContract = c.idContract
					ORDER BY data DESC, idjurnal desc) stari
	where c.stare is null
	
	IF OBJECT_ID('tempdb..#jurnalIntrodus') IS NULL
		CREATE TABLE #jurnalIntrodus (idJurnal INT, idContract int)

	INSERT INTO JurnalContracte (idContract, data, stare, explicatii, detalii, utilizator)
		OUTPUT inserted.idJurnal, inserted.idContract
		INTO #jurnalIntrodus(idJurnal, idContract)
	select idContract, data, ISNULL(stare,0), explicatii, detalii, @utilizator
	from @contracte

	/** In parametrul @parXML OUTPUT vom trimite ID-ul jurnalului introdus **/
	SET @parXML = (SELECT idJurnal AS idJurnal, idContract as idContract FROM #jurnalIntrodus FOR XML raw )
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wScriuJurnalPozContracte)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
