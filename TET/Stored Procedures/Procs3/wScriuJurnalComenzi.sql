
CREATE PROCEDURE wScriuJurnalComenzi @sesiune VARCHAR(50), @parXML XML
OUTPUT AS

	DECLARE 
		@idComanda INT, @data DATETIME, @explicatii VARCHAR(60), @stare VARCHAR(10), @iDoc int,
		@mesaj VARCHAR(500), @detalii XML, @utilizator VARCHAR(100), @rootXml varchar(50)

	declare 
		@comenzi table (idComanda int, data datetime, explicatii varchar(max), stare varchar(10), detalii xml)

	BEGIN TRY
		/* Se trimite cu root Date cand sunt afectate mai multe comenzi */
		if @parXML.exist('(/Date)')=1 
			set @rootXml='/Date/row'
		else
			set @rootXml='/row'

		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
		insert into @comenzi(idComanda, data, explicatii, stare, detalii)
		select idComanda, data, explicatii, stare, detalii
		from OPENXML(@iDoc, @rootXml)
			WITH 
			(
				idComanda int '@idComanda', 
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
		from @comenzi c
		cross apply (select top 1 stare 
						FROM JurnalComenzi j
						WHERE j.idLansare = c.idComanda
						ORDER BY data DESC) stari
		where c.stare is null
	
		IF OBJECT_ID('tempdb..#jIntrodus') IS NOT NULL
			DROP TABLE #jIntrodus

		CREATE TABLE #jIntrodus (idJurnal INT, idComanda int)

		INSERT INTO JurnalComenzi(idLansare, data, stare, explicatii, detalii, utilizator)
		OUTPUT inserted.idJurnal, inserted.idLansare INTO #jIntrodus(idJurnal, idComanda)
		select idComanda, data, ISNULL(stare,'P'), explicatii, detalii, @utilizator
		from @comenzi

		/** In parametrul @parXML OUTPUT vom trimite ID-ul jurnalului introdus **/
		SET @parXML = (SELECT idJurnal AS idJurnal, idComanda as idContract FROM #jIntrodus FOR XML raw )
END TRY
BEGIN CATCH
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
