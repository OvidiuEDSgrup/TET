
CREATE PROCEDURE wOPGenerareRezervare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@idContract INT, @mesaj VARCHAR(500), @gestiune VARCHAR(20), @gestiuneRezervari VARCHAR(20), @docRezervare XML, @zile_rezervare int, 
		@numarPozDoc VARCHAR(20), @docPlaje XML, @data DATETIME, @utilizator VARCHAR(100), @subunitate VARCHAR(9), @cod VARCHAR(20), 
		@idPozContract INT, @cantitate FLOAT, @fetch INT, @docJurnal XML, @idJurnal INT, @codspecific VARCHAR(20), @stare INT, @fara_mesaje bit

	select
		@gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@gestiuneRezervari = isnull(@parXML.value('(/*/@gestiunerezervari)[1]', 'varchar(20)'),(select top 1 val_alfanumerica from par where tip_parametru='GE' and parametru='REZSTOCBK')),
		@data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'),convert(datetime,(convert(char(10),getdate(),101)),101)),
		@fara_mesaje= isnull(@parXML.value('(/*/@fara_mesaje)[1]', 'bit'),0),
		@stare = @parXML.value('(/*/@stare)[1]', 'int')

	IF @stare = 0
	begin
		declare @docdef xml
		set @docdef=(select @idContract idContract for xml raw)
		exec wOPDefinitivareContract @sesiune=@sesiune, @parXML=@docdef
	end

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	EXEC luare_date_par 'UC','EXPREZ',0,@zile_rezervare OUTPUT,''
	if ISNULL(@zile_rezervare,0)=0
	--default 10 zile tinem o rezervare
		select @zile_rezervare=10

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	IF OBJECT_ID('tempdb..#pozitiiRezervare') IS NOT NULL
		DROP TABLE #pozitiiRezervare
	create table #pozitiiRezervare(idPozContract int,cod varchar(20),cantitate float,codspecific varchar(20))

	/** Citire date introduse in gridul de operatie **/
	insert into #pozitiiRezervare(idPozContract,cod,cantitate,codspecific)
	SELECT	
		D.cod.value('(@idPozContract)[1]', 'int') idPozContract, 
		D.cod.value('(@cod)[1]', 'varchar(20)') cod, 
		D.cod.value('(@derezervat)[1]', 'float') cantitate, 
		pz.cod_specific AS codspecific
	FROM @parXML.nodes('parametri/DateGrid/row') D(cod)
	INNER JOIN PozContracte pz ON pz.idPozContract = D.cod.value('(@idPozContract)[1]', 'int')

	IF NOT EXISTS (SELECT 1 FROM #pozitiiRezervare)
	begin
		insert into #pozitiiRezervare(idPozContract,cod,cantitate,codspecific)
		select 	idPozContract, cod,	cantitate, cod_specific
		from PozContracte
		where idContract=@idContract

		--Inainte era asa
		/*
			RAISERROR ('Nu exista pozitii pentru care sa fie generata rezervarea', 11, 1)
		*/
	end
	IF NOT EXISTS (SELECT 1 FROM #pozitiiRezervare WHERE cantitate > 0.0)
		RAISERROR ('Nu exista pozitii cu cantitati pozitive pentru care sa fie generata rezervarea', 11, 1)

	set @docPlaje=(select 'RZ' as tip, @utilizator utilizator for xml raw)
	EXEC wIauNrDocFiscale @parXML = @docPlaje, @NrDoc = @numarPozDoc OUTPUT

	/** Se consemneaza in jurnal faptul ca se genereaza rezervare si se ia ID-ul jurnalului scris **/
	SELECT @docJurnal = (SELECT @idContract idContract, GETDATE() data, 'Generare rezervare' explicatii, (select DATEADD(DAY,@zile_rezervare,GETDATE()) expirare_rez FOR XML raw,type) detalii for xml raw)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT
	SET @idJurnal = @docJurnal.value('(/*/@idJurnal)[1]', 'int')


SET @docRezervare = 
	(
		SELECT 
			@subunitate subunitate, 'TE' AS tip, @numarPozDoc AS numar, convert(VARCHAR(10), @data, 101) data, 
			@gestiune gestiune, @gestiuneRezervari gestprim, '1' AS fara_luare_date, '1' AS returneaza_inserate, 
			(
				SELECT 
					cod AS cod, convert(DECIMAL(15, 2), cantitate) AS cantitate, codspecific barcod, idPozContract as factura, idPozContract idlinie
				from #pozitiiRezervare 
				WHERE cantitate > 0.0
				FOR XML raw, type
			)
		FOR XML raw, type
	)

	EXEC wScriuPozDoc @sesiune = @sesiune, @parXML = @docRezervare OUTPUT
	-->generare inregistrari contabile
	exec faInregistrariContabile @dinTabela=0, @Subunitate=@subunitate, @Tip='TE', @Numar=@numarPozDoc, @Data=@data

	/** Se introduc in LegaturiContracte **/
	INSERT INTO LegaturiContracte (idJurnal, idPozContract, IdPozDoc)
	SELECT @idJurnal, PD.r.value('(@idlinie)[1]', 'int') , PD.r.value('(@idPozDoc)[1]', 'int')
	FROM @docRezervare.nodes('/row/docInserate/row') PD(r)

	if @fara_mesaje=0
		SELECT 
			'S-a generat rezervarea cu numarul de document ' + @numarPozDoc +' pentru codurile si cantitatile selectate in tabel!' AS textMesaj, 'Notificare' AS titluMesaj
		FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareRezervare)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
