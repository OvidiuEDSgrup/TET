
CREATE PROCEDURE wOPGenerareTransferSP @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY

	DECLARE 
		@idContract INT, @mesaj VARCHAR(500), @gestiune VARCHAR(20),@numarPozDoc VARCHAR(20), @docPlaje XML,
		@data DATETIME, @utilizator VARCHAR(100), @subunitate VARCHAR(9), @cod VARCHAR(20), @idPozContract INT, 
		@cantitate FLOAT, @fetch INT, @docJurnal XML, @idJurnal INT, @stare INT, @gestiune_primitoare varchar(20),@lm varchar(20), @docTransfer xml,
		@fara_mesaje bit=0, @detalii xml, @custodie int,@tert varchar(20), @cuRezervari bit, @gestiuneRezervari varchar(20)

	SELECT
		@gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),
		@gestiune_primitoare = @parXML.value('(/*/@gestiune_primitoare)[1]', 'varchar(20)'),
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@data = @parXML.value('(/*/@data)[1]', 'datetime'),
		@stare = @parXML.value('(/*/@stare)[1]', 'int'),
		@fara_mesaje = isnull(@parXML.value('(/*/@fara_mesaje)[1]', 'bit'),0),
		@lm = @parXML.value('(/*/@lm)[1]', 'varchar(20)'),
		@custodie=0

	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	IF @stare = 0
	begin
		declare @docdef xml
		set @docdef=(select @idContract idContract for xml raw)
		exec wOPDefinitivareContract @sesiune=@sesiune, @parXML=@docdef
	end

	/** Daca gestiunea primitoare este una de tip custodii vom trimite clientul in locatie**/
	select top 1 @custodie=isnull(detalii.value('(/*/@custodie)[1]', 'int'),0) from gestiuni where cod_gestiune=@gestiune_primitoare

	IF OBJECT_ID('tempdb..#pozitiiTransfer') IS NOT NULL
		DROP TABLE #pozitiiTransfer

	/** Citire date introduse in gridul de operatie **/
	SELECT	D.cod.value('(@idPozContract)[1]', 'int') idPozContract, 
			D.cod.value('(@cod)[1]', 'varchar(20)') cod, 
			D.cod.value('(@detransferat)[1]', 'float') cantitate
	INTO #pozitiiTransfer
	FROM @parXML.nodes('parametri/DateGrid/row') D(cod)
	INNER JOIN PozContracte pz ON pz.idPozContract = D.cod.value('(@idPozContract)[1]', 'int')

	IF NOT EXISTS (SELECT 1 FROM #pozitiiTransfer)
		RAISERROR ('Nu exista pozitii pentru care sa fie generate transferurile!', 11, 1)

	IF NOT EXISTS (SELECT 1 FROM #pozitiiTransfer WHERE cantitate > 0.0)
		RAISERROR ('Nu exista pozitii cu cantitati pozitive pentru care sa fie generat transferul', 11, 1)

	/** Se consemneaza in jurnal faptul ca se genereaza TE si se ia ID-ul jurnalului scris **/
	SELECT @docJurnal = (SELECT @idContract idContract, GETDATE() data, 'Generare transfer' explicatii FOR XML raw)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT
	SET @idJurnal = @docJurnal.value('(/*/@idJurnal)[1]', 'int')
		
	select @tert=rtrim(c.tert)+rtrim(isnull(c.punct_livrare,'')) from Contracte c where c.idContract=@idContract

	SET @docTransfer = (
			SELECT @subunitate subunitate, 'TE' AS tip, convert(VARCHAR(10), @data, 101) data,@lm lm, 
					@gestiune gestiune, @gestiune_primitoare gestprim, '1' AS fara_luare_date, '1' AS returneaza_inserate,
					@detalii as detalii, 
				(SELECT 
					p.cod AS cod, convert(decimal(17,3),/*SP */COALESCE((case when @cuRezervari =1 then prez.cantitate end), P.cantitate)) AS cantitate, /* SP*/
					p.idPozContract as idPozContract,(case when @custodie=1 then @tert else null end) as locatie, p.idPozContract idlinie,  prez.idPozDoc idpozdocrezervare
				FROM #pozitiiTransfer p
				LEFT JOIN LegaturiContracte lc on lc.idPozContract=p.idPozContract and @cuRezervari=1
				LEFT JOIN PozDoc prez on  prez.tip='TE' and prez.gestiune_primitoare=@gestiuneRezervari and prez.idPozDoc=lc.idPozDoc
				/*SP where  (@cuRezervari = 0 OR prez.idPozDoc is not null) SP*/
				FOR XML raw, type)
			FOR XML raw, type)
	
	if exists(select * from sysobjects where name='wScriuDoc')
		exec wScriuDoc @sesiune = @sesiune, @parXML = @docTransfer OUTPUT
	else
	begin
		if exists(select * from sysobjects where name='wScriuDocBeta')
			exec wScriuDocBeta @sesiune = @sesiune, @parXML = @docTransfer OUTPUT	
		else
			exec wScriuPozDoc @sesiune = @sesiune, @parXML = @docTransfer OUTPUT
	end

	/** Se introduc in LegaturiContracte **/
	INSERT INTO LegaturiContracte (idJurnal, idPozContract, IdPozDoc)
	SELECT @idJurnal, PD.r.value('(@idlinie)[1]', 'int') , PD.r.value('(@idPozDoc)[1]', 'int')
	FROM @docTransfer.nodes('/row/docInserate/row') PD(r)
	
	declare @idPozDoc int
	select top 1 @idPozDoc = idPozDoc from LegaturiContracte where idJurnal=@idJurnal
	select top 1 @numarPozDoc=rtrim(numar) from PozDoc where idPozDoc=@idPozDoc

	-->generare inregistrari contabile
	exec faInregistrariContabile @dinTabela=0, @Subunitate=@subunitate, @Tip='TE', @Numar=@numarPozDoc, @Data=@data

	declare @xml xml
	set @xml = (select @idContract idContract for xml raw)
	exec updateStareContract @sesiune=@sesiune, @parXML=@xml
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareTransferSP1')
		exec wOPGenerareTransferSP1 @sesiune=@sesiune, @parXML=@parXML

	if @fara_mesaje=0
		SELECT 'S-a generat transferul cu numarul de document ' + @numarPozDoc + ' pentru codurile si cantitatile selectate!' AS textMesaj, 'Notificare' AS titluMesaj
		FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareTransferSP)'
	RAISERROR (@mesaj, 11, 1)
END CATCH