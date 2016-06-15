
CREATE PROCEDURE wOPGenerareFactura @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareFacturaSP')
	begin
		exec wOPGenerareFacturaSP @sesiune = @sesiune, @parXML = @parXML output
		return
	end

IF EXISTS (select 1 from sysobjects where type='P' and name='wOPFacturareContracte')
begin	
	exec wOPFacturareContracte @sesiune=@sesiune, @parXML=@parXML
	return
end

--<<<<<<<<<<<<  DE AICI IN JOS E PROCEDURA LEGACY- NU SE MAI FOLOSESTE: TOTUL MERGE PRIN wOPFacturareContracte  >>>>>>>>>>>>>---



/**
	Procedura trateaza facturarea din comenzi de livrare.
	Exista cazul special in care in campul detalii din PozContracte avem @idSursaStorno, care inseamna ca acea pozitie (de regula cu cantitate negativa)
	provine din stornarea unei alte pozitii de pe o factura, iar acel @idSursaStorno reprezinta idPozDoc-ul acelei pozitii. Acest caz este tratat la 
	sfarsit prin apelul procedurii de stornare document (care genereaza intrari in LegaturiStornare, etc ... )

**/
	DECLARE 
		@mesaj VARCHAR(500), @cuRezervari INT, @gestiuneRezervari VARCHAR(20), @gestiune VARCHAR(20), @cod VARCHAR(20), 
		@numarPozDoc VARCHAR(9), @fetch INT, @docJurnal XML, @idJurnal INT, @idPozContract INT, @docPlaje XML, @utilizator VARCHAR(100), 
		@cantitate FLOAT, @idContract INT, @docFacturare XML, @subunitate VARCHAR(9), @data DATETIME, @lm VARCHAR(20), 
		@tert VARCHAR(20), @pret FLOAT, @stare INT, @aviznefacturat bit, @xml xml,@doc_returnat xml,@fara_mesaj bit,
		/** Variabile pt scrierea in AnexFac **/
		@numeDelegat VARCHAR(30), @mijlocTransport VARCHAR(30), @nrMijlocTransport VARCHAR(20), @seriaBuletin VARCHAR(10), 
		@numarBuletin VARCHAR(10), @eliberat VARCHAR(30), @observatii VARCHAR(200), @codspecific VARCHAR(20),@tipDoc char(2),
		@amRezervarePeComanda bit, @pctliv varchar(50), 
		/** Variabile pt. partea de pozitii din stornare **/
		@tips varchar(2), @datas datetime, @numars varchar(20),
		@datad datetime, @numard varchar(20), @facturad varchar(20), @datafactd datetime


	set @amRezervarePeComanda=0
	SET @gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)')	
	SET @tert = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
	SET @pctliv = @parXML.value('(/*/@pctliv)[1]', 'varchar(20)')
	SET @lm = @parXML.value('(/*/@lm)[1]', 'varchar(20)')
	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'), GETDATE())
	SET @aviznefacturat = isnull(@parXML.value('(/*/@aviznefacturat)[1]', 'bit'),0)
	/** Variabile pt scrierea in AnexFac **/
	SET @numeDelegat = @parXML.value('(/*/@numedelegat)[1]', 'varchar(30)')
	SET @mijlocTransport = @parXML.value('(/*/@mijloctransport)[1]', 'varchar(30)')
	SET @nrMijlocTransport = @parXML.value('(/*/@nrmijloctransport)[1]', 'varchar(20)')
	SET @seriaBuletin = @parXML.value('(/*/@seriabuletin)[1]', 'varchar(10)')
	SET @numarBuletin = @parXML.value('(/*/@numarbuletin)[1]', 'varchar(10)')
	SET @eliberat = @parXML.value('(/*/@eliberat)[1]', 'varchar(30)')
	SET @observatii = @parXML.value('(/*/@observatii)[1]', 'varchar(200)')
	SET @fara_mesaj = isnull(@parXML.value('(/*/@fara_mesaj)[1]', 'bit'),0)
	
	if exists(select 1 from delegexp where numele_delegatului=@numeDelegat) --Se va completa intotdeauna seria, numarul de buletin si eliberatul din aceasta tabela
	begin
		select @seriaBuletin=seria_buletin,@numarBuletin=numar_buletin,@eliberat=Eliberat
		from delegexp where numele_delegatului=@numeDelegat
	end

	select @stare=st.stare
	from 
		(select
			stare, RANK() over (order by data desc, idJurnal desc) rn
		 from JurnalContracte where idContract=@idContract
		) st
	where st.rn=1

	/** Daca se da facturare si comanda e in stare 0 **/
	IF @stare = 0
	begin
		declare @docdef xml

		set @docdef=(select @idContract idContract for xml raw)

		exec wOPDefinitivareContract @sesiune=@sesiune, @parXML=@docdef
	end

	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	/** Citire date introduse in gridul de operatie **/
	IF OBJECT_ID('tempdb..#pozitiiFactura') IS NOT NULL
		DROP TABLE #pozitiiFactura

	/** 
		Determinare daca se lucreaza cu gestiune de rezervari si daca exista rezervari pe comanda actuala 
		Daca am TE pe gestiune_primitoare = gestiunea de rezervari in PozDoc inseamna ca am rezervare pe aceasta comanda si voi factura din gestiune coresp.	
	**/
	if @cuRezervari =1
	IF EXISTS (select 1 from PozContracte pc JOIN LegaturiContracte lc on pc.idPozContract=lc.idPozContract AND pc.idContract=@idContract JOIN PozDoc pd on pd.idPozDoc=lc.idPozDoc and pd.Gestiune_primitoare=@gestiuneRezervari and pd.Tip='TE' and pd.Subunitate='1')
		set @amRezervarePeComanda=1

	SELECT	D.cod.value('(@idPozContract)[1]', 'int') idPozContract, 
			D.cod.value('(@cod)[1]', 'varchar(20)') cod, 
			D.cod.value('(@defacturat)[1]', 'float') defacturat, 
			D.cod.value('(@rezervat)[1]', 'float') rezervat, 
			(CASE @amRezervarePeComanda WHEN 1 THEN D.cod.value('(@rezervat)[1]', 'float') 
								ELSE D.cod.value('(@defacturat)[1]', 'float') END) AS defactcalc, 
			case when isnull(D.cod.value('(@gestiune)[1]', 'varchar(13)'),'')<>'' then D.cod.value('(@gestiune)[1]', 'varchar(13)') 
				else 				
					(CASE @amRezervarePeComanda WHEN 1 THEN @gestiuneRezervari ELSE @gestiune END)
				end	 AS gestiune, 
			pz.cod_specific AS codspecific, 
			pz.pret,
			isnull(nullif(D.cod.value('(@discount)[1]', 'float'),0), pz.discount) discount 
	INTO #pozitiiFactura
	FROM @parXML.nodes('*/DateGrid/row') D(cod)
	INNER JOIN PozContracte pz
		ON pz.idPozContract = D.cod.value('(@idPozContract)[1]', 'int')
		/** Pozitiile de stornare de pe alta factura se trateaza separat **/
		and pz.detalii.value('(/*/@idSursaStorno)[1]','int') is NULL 

	/**
		Daca toate codurile sunt de tip Servicii Prestate (S) in nomenclator
		Vom face tipul documentului AS
	**/
	if (select top 1 n.tip
			from #pozitiiFactura pf
			inner join nomencl n on pf.cod=n.cod
		order by n.tip)='S'
		set @tipDoc='AS'
	else
		set @tipDoc='AP'

	
	/** Se mai inseareaza linii in tabelul de trimis la PozDoc cu diferentele de cantitate intre
	cantitatea ceruta si cea rezervata **/
	IF @amRezervarePeComanda = 1
	BEGIN
		INSERT INTO #pozitiiFactura (idPozContract, cod, defacturat, rezervat, defactcalc, gestiune, codspecific, pret)
		SELECT idPozContract, cod, 0, 0, defacturat - rezervat, @gestiune, codspecific, pret
		FROM #pozitiiFactura
		WHERE defacturat - rezervat > 0.0  or defacturat<-0.001
	END

	IF NOT EXISTS (SELECT 1 FROM #pozitiiFactura where abs(defacturat) > 0.001) -- se pot factura si cantitati negative...
		RAISERROR ('Nu exista pozitii cu cantitate pentru care sa fie fie generata factura!', 11, 1)
	
	/** Luare numar plaja  **/
	SET @docPlaje = '<row/>'
	SET @docPlaje.modify('insert attribute tip {"AP"} into (/row)[1]')
	SET @docPlaje.modify('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')

	EXEC wIauNrDocFiscale @parXML = @docPlaje, @NrDoc = @numarPozDoc OUTPUT

	set @doc_returnat= (select @tipDoc tip, @numarPozDoc numar for xml RAW)
	set @parXML=@doc_returnat

	/** Se consemneaza in jurnal faptul ca se genereaza rezervare si se ia ID-ul jurnalului scris **/
	SELECT @docJurnal = ( SELECT @idContract idContract, GETDATE() data, 'Generare factura' explicatii FOR XML raw )
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT
	SET @idJurnal = @docJurnal.value('(/*/@idJurnal)[1]', 'int')

	/** Scriere in AnexaFac- o singura data **/
	IF NOT EXISTS (SELECT 1 FROM anexafac WHERE Subunitate = @subunitate AND Numar_factura = @numarPozDoc)
		INSERT anexafac (Subunitate, Numar_factura, Numele_delegatului, Seria_buletin, Numar_buletin, Eliberat, Mijloc_de_transport, 
			Numarul_mijlocului, Data_expedierii, Ora_expedierii, Observatii)
		VALUES (@subunitate, @numarPozDoc, @numeDelegat, @seriaBuletin, @numarBuletin, @eliberat, @mijlocTransport, 
			@nrMijlocTransport, @data, '', @observatii)

	/** Scriere in PozDoc  **/	
	SET @docFacturare = 
	(
		SELECT top 1
			@subunitate AS subunitate, @tipDoc AS tip, @numarPozDoc AS numar, CONVERT(VARCHAR(10), @data, 101) data, 
			@lm lm, @tert tert, @pctliv punctlivrare, @aviznefacturat as aviznefacturat,
			'1' AS fara_luare_date, '1' AS returneaza_inserate, 
			(case when detalii.value('(/*/@comanda)[1]','varchar(20)') IS NOT NULL then detalii.value('(/*/@comanda)[1]','varchar(20)') end) comanda,
			(
				SELECT 
					pf.cod cod, convert(DECIMAL(15, 2), pf.defactcalc) cantitate, pf.gestiune gestiune, 
					(CASE WHEN pf.codspecific IS NOT NULL THEN pf.codspecific END) AS barcod, 
					convert(DECIMAL(15, 5), pf.pret) pvaluta,
					@idJurnal idjurnalcontract, 
					pf.idPozContract idpozcontract,
					pf.discount discount,
					(case when pc.detalii.value('(/*/@comanda)[1]','varchar(20)') IS NOT NULL then pc.detalii.value('(/*/@comanda)[1]','varchar(20)') end) comanda
				from #pozitiiFactura pf
				JOIN PozContracte pc on pc.idPozContract=pf.idPozContract
				WHERE abs(defactcalc) > 0.001
				FOR XML raw, type)
		from Contracte where idContract=@idContract
		FOR XML raw, type
	)
	EXEC wScriuPozDoc @sesiune = @sesiune, @parXML = @docFacturare OUTPUT
	-->generare inregistrari contabile
	exec faInregistrariContabile @dinTabela=0, @Subunitate=@subunitate, @Tip=@tipDoc, @Numar=@numarPozDoc, @Data=@data

	IF OBJECT_ID('tempdb..#returPozDoc') IS NOT NULL
		DROP TABLE #returPozDoc

	SELECT PD.r.value('(@idPozDoc)[1]', 'int') idPozDoc
		INTO #returPozDoc
	FROM @docFacturare.nodes('/row/docInserate/row') PD(r)

	
	/** Iau ( o singura data, pt ca documentul e acelasi) datele noului document din pozdoc pt. a le folosi mai jos la tratarea pozitiilor storno **/
	if @numard is null 
		select top 1
				@numard= RTRIM(pd.numar), @datad=pd.data, @facturad=RTRIM(pd.factura), @datafactd = pd.Data_facturii
		from #returPozDoc rpd
		JOIN pozdoc pd ON rpd.idpozdoc=pd.idpozdoc


	/** Tratarea pozitiilor storno de pe comanda (au @idSursaStorno in detalii) **/

	select 
		idPozContract idPozContract, detalii.value('(/*/@idSursaStorno)[1]','int') idSursaStorno, cantitate cantitate
	into #pozitii_din_stornare
	from PozContracte where idContract=@idContract and detalii.value('(/*/@idSursaStorno)[1]','int') is not NULL

	declare @idSursaStorno int, @docStorn xml

	select top 1 @idSursaStorno= idSursaStorno,@idPozContract=idpozContract from #pozitii_din_stornare

	while exists (select 1 from #pozitii_din_stornare)
	begin
		set @docStorn=
		(
			SELECT
				RTRIM(tip) tip, data data, RTRIM(numar) numar, @datad datadoc, @numard numardoc, @facturad facturadoc,
				@datafactd dataFactDoc, '1' fara_rezervare,
				(
					select 
						pds.cantitate cantitate_stornoMax, pds.cantitate cantitate_storno, pds.cantitate cantitate, '1' subunitate, rtrim(pd.Tip) tip,
						pd.data data, RTRIM(pd.numar) numar, rtrim(pd.numar_pozitie) numar_pozitie, pd.idPozDoc idPozDoc					
					from #pozitii_din_stornare pds
					JOIN pozdoc pd on pds.idSursaStorno=pd.idPozDoc and pds.idSursaStorno=@idSursaStorno
					for xml raw, root('DateGrid'),TYPE
				)
			from PozDoc where idPozDoc=@idSursaStorno
			for xml RAW('parametri')			
		)

		exec wOPStornareDocument @sesiune=@sesiune, @parXML=@docStorn

		INSERT INTO LegaturiContracte (idJurnal, idPozContract, IdPozDoc)
		SELECT top 1 @idJurnal, @idPozContract, idStorno
		from LegaturiStornare
		where idSursa=@idSursaStorno

		delete from #pozitii_din_stornare where idSursaStorno=@idSursaStorno
		select top 1 @idSursaStorno= idSursaStorno,@idPozContract=idpozContract from #pozitii_din_stornare
	end

	set @xml = (select @idContract idContract for xml raw)
	exec updateStareContract @sesiune=@sesiune, @parXML=@xml
	
	if @fara_mesaj = 0
		SELECT 'S-a generat factura '+@numarPozDoc+ ' pentru codurile si cantitatile selectate in tabel!' AS textMesaj, 'Notificare' AS titluMesaj
		FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareFactura)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
