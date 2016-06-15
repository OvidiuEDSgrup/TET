
CREATE PROCEDURE wOPGenerareReceptieComanda @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @tert varchar(20), @lm varchar(20), @gestiune varchar(20), @data datetime, @factura varchar(20), @data_facturii datetime,
		@idContract int, @numarRM varchar(20), @utilizator varchar(100),@mesaj varchar(max), @idJurnalContract int, @valuta varchar(20),
		@curs float, @docPozDoc xml, @docJurnalContracte xml, @docPlaja xml, @stare int, @facturanesosita int, @detalii XML,
		@tipContract varchar(50), @data_scadentei datetime, @nr_receptie varchar(20)

	SELECT @tert = @parXML.value('(/*/@tert)[1]', 'varchar(20)'),
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@lm = @parXML.value('(/*/@lm)[1]', 'varchar(20)'),
		@gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),
		@data = @parXML.value('(/*/@data)[1]', 'datetime'),
		@data_facturii = @parXML.value('(/*/@data_facturii)[1]', 'datetime'),
		@data_scadentei = @parXML.value('(/*/@data_scadentei)[1]', 'datetime'),
		@factura = @parXML.value('(/*/@factura)[1]', 'varchar(100)'),
		@stare = @parXML.value('(/*/@stare)[1]', 'int'),
		@facturanesosita = @parXML.value('(/*/@facturanesosita)[1]', 'int'),
		@nr_receptie = NULLIF(@parXML.value('(/*/@nr_receptie)[1]', 'varchar(20)'), '')

	if @parXML.exist('(/*/detalii)[1]') = 1
		SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	select top 1  
		@tipContract = c.tip,
		@curs= ISNULL(@parXML.value('(/*/@curs)[1]','float'), curs), 
		@valuta=isnull(@parXML.value('(/*/@valuta)[1]','varchar(50)'),valuta)
	from Contracte c
	where idContract=@idContract
	
	/** Daca nu se mai prepopuleaza macheta, dar se specifica o receptie existenta, sa ia datele receptiei. */
	IF EXISTS (SELECT 1 FROM doc WHERE Tip = 'RM' AND Numar = @nr_receptie AND Data = @data AND ISNULL(@valuta, '') = '')
	BEGIN
		SELECT @tert = RTRIM(d.Cod_tert), @lm = RTRIM(d.Loc_munca), @gestiune = RTRIM(d.Cod_gestiune),
			@factura = RTRIM(d.Factura), @data_facturii = d.Data_facturii
		FROM doc d
		WHERE d.Tip = 'RM' AND d.Numar = @nr_receptie AND d.Data = @data
	END

	if  @valuta<>'' and @curs=0
		raiserror('Comanda este in valuta, trebuie sa introduceti un curs valutar!',11,1)

	if exists (select * from StariContracte sc where sc.tipContract=@tipContract and sc.stare=@stare and isnull(facturabil,0)<>1)
		raiserror('Comanda este in o stare care nu permite generarea. Modificati starea comenzii!',11,1)


	/** Iau pozitii din Grid pt. a le trimite la wScriuPozDoc RM  */
	SELECT	D.cod.value('(@idPozContract)[1]', 'int') idPozContract, 
			D.cod.value('(@cod)[1]', 'varchar(20)') cod, 
			D.cod.value('(@cantitate)[1]', 'float') cantitate, 
			D.cod.value('(@cant_receptionata)[1]', 'float') cant_receptionata, 
			D.cod.value('(@comanda)[1]', 'varchar(20)') comanda,
			D.cod.value('(@pret)[1]', 'float') pret,
			row_number() over (order by newid()) idlinie
	INTO #pozitiiReceptie
	FROM @parXML.nodes('*/DateGrid/row') D(cod)

	--daca exista vreo pozitie cu cantitate<> 0 dar cu pret 0 -> eroare
	if EXISTS (select 1 from #pozitiiReceptie where pret=0 and abs(cantitate)>0.00001)
		raiserror('Exista pozitii cu pret 0!',11,1)
	
	--eroare daca se identifica pozitii pe care prin generarea receptiei s-ar depasi cantitatea comandata
	if exists (select 1 from #pozitiiReceptie pr 
					inner join pozcontracte pc on pc.idpozcontract=pr.idpozcontract 
						and convert(decimal (17,5),pr.cantitate+isnull(pr.cant_receptionata,0))>convert(decimal (17,5),isnull(pc.cantitate,0))
						and convert(decimal (17,5),pr.cantitate)>0.00001
				)
		raiserror('Exista pozitii pentru care cantitatea receptionata depaseste cantitatea comandata!',11,1)


	/** Pregatim documentul pt. apelul de scriere a documentului de receptie 
		-> doar cele cu abs(cantitate)>0.001 
	**/
	set @docPozDoc=
	(
		select
			@nr_receptie AS numar, '1' AS fara_luare_date, '1' AS returneaza_inserate, 'RM' AS tip, 
			@factura AS factura, CONVERT(VARCHAR(10), @data, 101) AS data, 
			CONVERT(VARCHAR(10), @data_facturii, 101) AS datafacturii, CONVERT(VARCHAR(10), @data_scadentei,101) AS datascadentei,
			@tert AS tert, @gestiune AS gestiune, @lm AS lm, isnull(@valuta,'') AS valuta, isnull(@curs,0) AS curs,
			@facturanesosita AS facturanesosita, @detalii AS detalii,
			(
				select	
					cod AS cod, comanda AS comanda, 
					convert(DECIMAL(15, 3), cantitate) AS cantitate, 
					convert(DECIMAL(15, 5),(case when @curs<>0 then pret*@curs else pret end)) AS pstoc,		
					convert(DECIMAL(15, 5),(case when @curs<>0 then pret*@curs else pret end)*1.24) AS pamanunt,				
					convert(DECIMAL(15, 5), pret) AS pvaluta,
					@factura AS factura, idlinie AS idlinie			
				from #pozitiiReceptie
				where abs(cantitate)>0.001
				for xml raw, type
			)
		for xml raw, type
	)

	if object_id('wScriuDoc') is not null -- conceptul idlinie nu merge decat cu wScriuDoc
		exec wScriuPozDoc @sesiune=@sesiune, @parXML=@docPozDoc OUTPUT
	else
		exec wScriuDocBeta @sesiune=@sesiune, @parXML=@docPozDoc OUTPUT

	declare @ddoc int
	EXEC sp_xml_preparedocument @ddoc OUTPUT, @docPozDoc

	IF OBJECT_ID('tempdb..#xmlPozitiiReturnate') IS NOT NULL
		DROP TABLE #xmlPozitiiReturnate
	
	SELECT
		idlinie, idPozDoc
	INTO #xmlPozitiiReturnate
	FROM OPENXML(@ddoc, '/row/docInserate/row')
	WITH
	(
		idLinie int '@idlinie',
		idPozDoc	int '@idPozDoc'

	)
	EXEC sp_xml_removedocument @ddoc 
		
	create table #Legaturi (a bit)
	exec CreazaDiezLegaturi

	insert into #Legaturi (idPozContract, idPozDoc)
	select
		it.idPozContract, pr.idPozDoc
	from #pozitiiReceptie it
	JOIN #xmlPozitiiReturnate pr on pr.idlinie=it.idLinie

	declare @xml_proc xml
	set @xml_proc= (select 'Generare receptie' explicatii for xml raw)
	exec wOPTrateazaLegaturiSiStariContracte @sesiune=@sesiune, @parXML=@xml_proc
		
	select top 1 @numarRM =  rtrim(numar) from pozdoc p JOIN #xmlPozitiiReturnate x on x.idpozdoc=p.idpozdoc
	select 
		'S-a generat documentul de receptie cu numarul: '+ISNULL(CONVERT(varchar,@numarRM),'-') +' !'  as textMesaj, 'Generat receptie' as titluMesaj
	for xml raw, root('Mesaje')
END TRY
BEGIN CATCH
	set @mesaj=ERROR_MESSAGE()+ ' (wOPGenerareReceptieComanda)'
	raiserror(@mesaj, 11, 1)
END CATCH
