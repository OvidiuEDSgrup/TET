IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wOPGenerareTransferSP')
	DROP PROCEDURE wOPGenerareTransferSP
GO

CREATE PROCEDURE wOPGenerareTransferSP @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY

	DECLARE 
		@idContract INT, @mesaj VARCHAR(500), @gestiune VARCHAR(20),@numarPozDoc VARCHAR(20), @docPlaje XML,
		@data DATETIME, @utilizator VARCHAR(100), @subunitate VARCHAR(9), @cod VARCHAR(20), @idPozContract INT, 
		@cantitate FLOAT, @fetch INT, @docJurnal XML, @idJurnal INT, @stare INT, @gestiune_primitoare varchar(20),@lm varchar(20), @docTransfer xml,
		@fara_mesaje bit=0, @detalii xml, @custodie int,@tert varchar(20), @cuRezervari bit, @gestiuneRezervari varchar(20),
		@nrformular varchar(10), @CLFrom varchar(100), @caleRaport varchar(1000), @numefisier varchar(200), @calefisier varchar(200),
		@profile_name varchar(50), @file_attachments varchar(1000), @subject varchar(200), @textemail varchar(1000),
		@emailGest varchar(100)

	SELECT
		@gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),
		@gestiune_primitoare = @parXML.value('(/*/@gestiune_primitoare)[1]', 'varchar(20)'),
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@data = @parXML.value('(/*/@data)[1]', 'datetime'),
		@stare = @parXML.value('(/*/@stare)[1]', 'int'),
		@fara_mesaje = isnull(@parXML.value('(/*/@fara_mesaje)[1]', 'bit'),0),
		@lm = @parXML.value('(/*/@lm)[1]', 'varchar(20)'),
		@nrformular=upper(ISNULL(@parXML.value('(/*/@nrformular)[1]', 'varchar(10)'), '')),
		@custodie=0

	if @parXML.exist('(/*/detalii)[1]')=1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	set @calefisier=(select rtrim(rtrim(p.URL)+'/'+REPLACE(REPLACE(P.CALEFORM,rtrim(P.CALERIA),''),'\',''))+'/'
		from (select p.Parametru, p.Val_alfanumerica
		from par p where Tip_parametru='AR' 
		and Parametru IN ('CALEFORM','CALERIA','URL')) AS S
		PIVOT (MAX(val_alfanumerica) FOR parametru in ([CALEFORM],[CALERIA],[URL])) AS P)
	
	IF @stare = 0
	begin
		declare @docdef xml
		set @docdef=(select @idContract idContract for xml raw)
		exec wOPDefinitivareContract @sesiune=@sesiune, @parXML=@docdef
	end

	/** Daca gestiunea primitoare este una de tip custodii vom trimite clientul in locatie**/
	select top 1 @custodie=isnull(detalii.value('(/*/@custodie)[1]', 'int'),0),
		@emailGest=ISNULL(detalii.value('(/row/@email)[1]','varchar(100)'),'')
	from gestiuni where cod_gestiune=@gestiune_primitoare

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
	
	if object_id('temdb..#expeditie') is not null
		drop table #expeditie
	
	select tip='PROPUTILIZ', Cod=@Utilizator, Cod_proprietate='UltFormGenTE', Valoare=isnull(@nrformular,''), Valoare_tupla=@nrformular 
	into #expeditie where isnull(@nrformular,'')<>''
	
	delete pp
	from proprietati pp join #expeditie e  on e.tip=pp.Tip and e.Cod=pp.Cod and e.Cod_proprietate=pp.Cod_proprietate --and pp.Valoare_tupla=''
	
	insert proprietati (Tip,Cod,Cod_proprietate,Valoare,Valoare_tupla)
	select e.tip,e.Cod,e.Cod_proprietate,e.Valoare,e.Valoare_tupla 
	from #expeditie e 
		left join proprietati pp on e.tip=pp.Tip and e.Cod=pp.Cod and e.Cod_proprietate=pp.Cod_proprietate --and pp.Valoare_tupla=''
	where pp.Valoare is null
	
	if @fara_mesaje=0
		SELECT 'S-a generat transferul cu numarul de document ' + @numarPozDoc + ' pentru codurile si cantitatile selectate!' AS textMesaj, 'Notificare' AS titluMesaj
		FOR XML raw, root('Mesaje')
	
	if @nrformular<>'' and @@TRANCOUNT<=0
	begin
		declare @paramXmlString xml
			
		select @CLFrom=CLFrom, @caleRaport=rtrim(CLWhere) from antform where numar_formular=@nrformular
		set @numefisier='Transfer_'+ISNULL(rtrim(@numarPozDoc),'')+(case when @clfrom<>'Raport' then '.doc' else '' end)
		set @paramXmlString= (select 'TE' as tip, @nrformular as nrform, rtrim(@numarPozDoc) as numar, @data as data,
			@numefisier as numefisier, @numefisier as numeFisier, (case when @CLFrom='Raport' then @caleRaport end) as caleRaport,
			0 as scriuavnefac, 0 as inXML, 1 as faraMesaj, 1 as faraMesaje 
			for xml raw)
			
		if @CLFrom='Raport'
			exec wExportaRaport @sesiune=@sesiune, @parXML=@paramXmlString
		else 
			exec wTipFormular @sesiune=@sesiune, @parXML=@paramXmlString 
		
		set @file_attachments=RTRIM(@calefisier)+RTRIM(@numefisier)+(case when @CLFrom='raport' then '.PDF' else '' end)
	end
	
	if isnull(@emailGest, '')<>''
	begin
		set @subject='Transfer de la gestiunea '+rtrim(@gestiune)
		set @textemail='Aveti transferul '+ @numarPozDoc + ' catre gestiunea dvs.'+CHAR(10)+CHAR(13)
			+@file_attachments 
		
		exec msdb..sp_send_dbmail @Profile_name=@profile_name, @recipients=@emailGest, @subject=@subject, 
			@body=@textemail--, @file_attachments = @file_attachments
	end
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareTransferSP)'
	RAISERROR (@mesaj, 11, 1)
END CATCH