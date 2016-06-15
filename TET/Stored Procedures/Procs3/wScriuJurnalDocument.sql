
CREATE PROCEDURE wScriuJurnalDocument @sesiune VARCHAR(50), @parXML XML
OUTPUT AS

	DECLARE 
		@tip varchar(2), @numar varchar(20), @data DATETIME, @explicatii VARCHAR(60), @stare VARCHAR(10), 
		@iDoc int, @mesaj VARCHAR(500), @detalii XML, @utilizator VARCHAR(100), @rootXml varchar(50)

	declare 
		@documente table (tip varchar(2), numar varchar(20), data datetime, explicatii varchar(max), stare varchar(10), detalii xml)

	BEGIN TRY
		/* Se trimite cu root Date cand sunt afectate mai multe documente */
		if @parXML.exist('(/Date)')=1 
			set @rootXml='/Date/row'
		else
			set @rootXml='/row'

		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
		insert into @documente(tip, numar, data, explicatii, stare, detalii)
		select tip, numar, data, explicatii, stare, detalii
		from OPENXML(@iDoc, @rootXml)
			WITH 
			(
				tip varchar(2) '@tip', 
				numar varchar(20) '@numar', 
				data datetime '@data',
				explicatii varchar(max) '@explicatii',
				stare varchar(10) '@stare',
				detalii xml 'detalii/row'
			)
		exec sp_xml_removedocument @iDoc

		/*** Utilizator */
		EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

		/** Daca nu se trimite starea va ramane in starea anterioara **/
		update c
			set stare = stari.stare
		from @documente c
		cross apply (select top 1 stare 
						FROM JurnalDocumente j
						WHERE j.tip=c.tip and j.numar=c.numar and j.data=c.data
						ORDER BY data_operatii DESC) stari
		where c.stare is null
	
		IF OBJECT_ID('tempdb..#jIntrodus') IS NOT NULL
			DROP TABLE #jIntrodus

		CREATE TABLE #jIntrodus (idJurnal INT, tip varchar(2), numar varchar(20), data datetime)

		INSERT INTO JurnalDocumente(tip, numar, data, data_operatii, stare, explicatii, detalii, utilizator)
		OUTPUT inserted.idJurnal, inserted.tip, inserted.numar, inserted.data INTO #jIntrodus(idJurnal,tip, numar, data)
		select tip, numar, data, GETDATE(), stare, explicatii, detalii, @utilizator
		from @documente	where NULLIF(stare,'') IS NOT NULL

		/** In parametrul @parXML OUTPUT vom trimite ID-ul jurnalului(sau jurnalelor) introdus(e) **/
		SET @parXML = (SELECT idJurnal AS idJurnal, tip, numar, data FROM #jIntrodus FOR XML raw )
END TRY
BEGIN CATCH
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
