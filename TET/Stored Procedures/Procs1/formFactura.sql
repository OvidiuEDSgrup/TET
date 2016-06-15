/**
	Formularul este folosit pentru a lista set-uri de facturi (sau doar 1). Filtrele suportate sunt vizibile in macheta operatiei de Listare facturi din ASiSria
	Filtre: 
				@datajos datetime		-	data inferioara filtrata in tabelele Doc (data) si PozDoc (data)
				@datasus datetime		-	data superioara filtrata in tabelele Doc (data) si PozDoc (data)

				@factura varchar(20)	-	numarul de factura-> daca este completat va fi filtrat tot doar pt acea factura
				@grupaTerti varchar(20)	-	grupa de terti filtrata in tabelele Doc (cod_tert) si PozDoc (tert)
				@gestiune varchar(20)	-	gestiunea filtrata in tabelele Doc (cod_gestiune) si PozDoc (gestiune)
				
				<facturi>				-	din operatii, se completa mai multe facturi in XML, pentru a filtra doar acele facturi.

**/
CREATE PROCEDURE formFactura @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @unitate VARCHAR(100), @adresa VARCHAR(100), @cui VARCHAR(100), @ordreg VARCHAR(100), @jud VARCHAR(100), @ct VARCHAR(100), 
		@proctva VARCHAR(100), @banca varchar(100), @numarsus varchar(100), @numarjos varchar(100), @ion varchar(100), @cnp varchar(100),
		@mesaj varchar(1000), @subunitate varchar(10), @datasus datetime, @datajos datetime,@cTextSelect nvarchar(max), @debug bit, 
		@gestiune varchar(20), @email varchar(100), @factura varchar(20), @grupaTerti varchar(20), @utilizator varchar(50), @filtruFacturi bit,@tip varchar(2),@data datetime
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	/** Filtre **/
	SELECT @datasus= @parXML.value('(/*/@datasus)[1]', 'datetime'),
	@datajos= @parXML.value('(/*/@datajos)[1]', 'datetime'),
	@gestiune= isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),''),
	@factura= isnull(@parXML.value('(/*/@factura)[1]', 'varchar(20)'),''),
	@grupaTerti= isnull(@parXML.value('(/*/@grupa_terti)[1]', 'varchar(20)'),''),
	@tip=isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'),'AP'),
	@data= @parXML.value('(/*/@data)[1]', 'datetime')
	
	-- pentru filtrare pe anumite facturi
	declare @facturi table(factura varchar(20), data_facturii datetime)
	insert into @facturi(factura, data_facturii)
	select   
		xFact.row.value('@factura', 'varchar(20)') as idJurnal,
		xFact.row.value('@data_facturii', 'datetime') as idContract
	from @parXML.nodes('*/facturi/row') as xFact(row)
	
	if exists (select * from @facturi)
	begin 
		-- daca se tiparesc facturi, nu mai conteaza @datrajos si sus din filtru
		set @filtruFacturi=1
		select 
			@datajos = min(data_facturii), 
			@datasus=max(data_facturii)
		from @facturi
	end
	else
		set @filtruFacturi=0
	
	/* Alte **/
	SET @debug= isnull(@parXML.value('(/*/@debug)[1]', 'int'),0)
	IF @datajos IS NULL
		set @datajos=@data

	IF @datasus IS NULL
		set @datasus=@data

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF OBJECT_ID('tempdb..#PozDocFiltr') IS NOT NULL
		DROP TABLE #PozDocFiltr

	IF OBJECT_ID('tempdb..#DocFiltr') IS NOT NULL
		DROP TABLE #DocFiltr

	/** Prefiltrare din tabela DOC pentru a nu lucra cu toata **/
	create table #DocFiltr(factura varchar(20), data_facturii datetime, gestiune_primitoare varchar(20), valoare decimal(20,2), tva_22 decimal(20,2),
		GRNETA varchar(500), TFDISC varchar(500), DISCOUNT varchar(500), VALFDISC varchar(500),
		TVAFDISC varchar(500), VALDISC varchar(500),  TVADISC varchar(500), TVAPOZ varchar(500)
	)

	insert into #DocFiltr(factura, data_facturii, gestiune_primitoare, valoare, tva_22)
	SELECT doc.factura, doc.data_facturii, max(doc.gestiune_primitoare) gestiune_primitoare, sum(doc.valoare) valoare, sum(doc.tva_22) tva_22
	FROM doc
	WHERE doc.subunitate = @subunitate
		AND tip = @tip
		and data between @datajos and @datasus
		and (@gestiune='' or Cod_gestiune=@gestiune)
		and (@factura=''  OR factura=@factura)
		and (@grupaTerti ='' OR exists (select * from terti t where t.subunitate=@subunitate and t.tert=doc.Cod_tert and t.Grupa=@grupaTerti))
		and isnull(doc.factura,'') <> ''
		and (@filtruFacturi=0 or exists (select * from @facturi f where f.factura=doc.Factura and f.data_facturii=doc.Data_facturii))
	group by doc.factura, doc.data_facturii

	/** Pragatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	CREATE TABLE [dbo].[#PozDocFiltr] ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_valuta] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, 
		[Adaos] [real] NOT NULL, [Pret_vanzare] [float] NOT NULL, [Pret_cu_amanuntul] [float] NOT NULL, [TVA_deductibil] [float] NOT NULL, 
		[Cota_TVA] [real] NOT NULL, [Cod_intrare] [varchar](13) NOT NULL, [Locatie] [varchar](30) NOT NULL, [Data_expirarii] [datetime] NOT NULL, 
		[Loc_de_munca] [varchar](9) NOT NULL, [Comanda] [varchar](40) NOT NULL, [Barcod] [varchar](30) NOT NULL, 
		[Discount] [real] NOT NULL, [Tert] [varchar](13) NOT NULL, [Factura] [varchar](20) NOT NULL, 
		[Gestiune_primitoare] [varchar](13) NOT NULL, [Numar_DVI] [varchar](25) NOT NULL, [Valuta] [varchar](3) NOT NULL, [Curs] [float] NOT NULL, 
		[Data_facturii] [datetime] NOT NULL, [Data_scadentei] [datetime] NOT NULL, [Contract] [varchar](20) NOT NULL
		)

	INSERT INTO #PozDocFiltr (
		Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, 
		TVA_deductibil, Cota_TVA, Cod_intrare, Locatie, Data_expirarii, Loc_de_munca, Comanda, Barcod, Discount, Tert, 
		Factura, Gestiune_primitoare, Numar_DVI, Valuta, Curs, Data_facturii, Data_scadentei, Contract
		)
	SELECT rtrim(max(Numar)), rtrim(Cod), max(Data) data, max(rtrim(Gestiune)), sum(Cantitate), max(Pret_valuta), max(Pret_de_stoc), 
		MAX(Adaos), max(Pret_vanzare), max(Pret_cu_amanuntul), sum(TVA_deductibil), max(Cota_TVA), MAX(rtrim(Cod_intrare)), 
		MAX(rtrim(Locatie)), max(Data_expirarii), max(Loc_de_munca), max(rtrim(Comanda)), max(rtrim(Barcod)), 
		max(Discount), max(rtrim(pz.Tert)), rtrim(Factura), max(rtrim(Gestiune_primitoare)), max(Numar_DVI), max(Valuta), 
		max(Curs), Data_facturii, max(Data_scadentei), MAX(rtrim(Contract))
	FROM pozdoc pz
	--LEFT JOIN terti t on t.tert=pz.Tert and t.Subunitate=@subunitate
	WHERE pz.subunitate = @subunitate
		AND pz.tip = @tip
		AND pz.data BETWEEN @datajos AND @datasus
		AND (@gestiune='' OR pz.Gestiune = @gestiune)
		AND (@factura=''  OR pz.factura=@factura)
		and (@grupaTerti ='' OR exists (select * from terti t where t.subunitate=@subunitate and t.tert=pz.Tert and t.Grupa=@grupaTerti))
		and (@filtruFacturi=0 or exists (select * from @facturi f where f.factura=pz.Factura and f.data_facturii=pz.Data_facturii))
		AND isnull(pz.Factura, '') <> ''
	group by pz.factura, pz.data_facturii, pz.cod

	create index IX1 on #pozdocfiltr(factura,data_facturii)
	create index IX2 on #pozdocfiltr(cod)
	create index IX3 on #pozdocfiltr(cantitate, pret_valuta)

	/*
		In tabela prefiltrata #DocFiltr se completeaza anumite valori reprezentative poziilor (valoare, tva, discount, samd) pentru a avea datele
		agregata (nu vom mai folosi MAX, MIN) samd 
	*/

	update d
	set GRNETA=grupate.GRNETA, TFDISC=grupate.TFDISC, DISCOUNT= grupate.DISCOUNT, VALFDISC=grupate.VALFDISC,
		TVAFDISC=grupate.TVAFDISC, VALDISC = grupate.VALDISC, TVAPOZ=grupate.TVAPOZ, Valoare=grupate.Valoare, Tva_22=grupate.TVA_deductibil
	from #DocFiltr d
	INNER JOIN (
		select 
			p.Factura factura, p.Data_facturii data, 
			convert(CHAR(20), convert(MONEY, round(sum(p.cantitate * p.pret_valuta), 2)), 1) AS VAL, 
			round(sum(p.cantitate * p.pret_vanzare), 2) valoare,
			round(sum(TVA_deductibil), 2) TVA_deductibil,
			convert(CHAR(20), convert(MONEY, round(sum(p.cantitate * p.pret_valuta * p.cota_tva / 100), 2)), 1) TVAPOZ,
			convert(varchar(500),round(sum(CASE WHEN p.cantitate <= 0 THEN 0 ELSE p.cantitate * n.greutate_specifica END), 2)) GRNETA,
			(case when SUM(p.discount) > 0 then 
				convert(CHAR(15), convert(MONEY,round( sum(p.cantitate * p.pret_valuta), 2),1))  end) TFDISC,
			(case when SUM(p.discount)>0 then 
				convert(CHAR(15), convert(MONEY, - 1 * round(sum(p.cantitate * (p.pret_valuta - p.pret_vanzare)), 2), 1))  END) DISCOUNT,
			(case when sum(p.discount) >0 then
				convert(CHAR(15), convert(MONEY, - round( sum(p.cantitate * p.pret_valuta), 2), 1)  )END) VALFDISC,
			(case when sum(p.discount) >0 then 
				convert(CHAR(15), convert(MONEY, - round((sum(p.cantitate * p.pret_valuta * p.cota_tva / 100)), 2)), 1)  END)  TVAFDISC,
			(case when sum(p.discount) >0 then 
				convert(CHAR(15), convert(MONEY, - 1 * round(sum(p.cantitate * (p.pret_valuta - p.pret_vanzare)), 2)), 1)  END)  VALDISC,
			(case when sum(p.discount) >0 then 
				convert(CHAR(15), convert(MONEY, - round( sum(p.cantitate * p.pret_valuta * p.cota_tva / 100 - p.tva_deductibil), 2)), 1)  END) TVADISC
		from #PozDocFiltr p
		JOIN nomencl n on n.Cod=p.cod
		group by p.factura, p.Data_facturii
			) grupate on grupate.factura=d.Factura and grupate.data=d.data_facturii

	/**
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
	
	SELECT 
		@unitate = max(case when parametru='NUME' then rtrim(val_alfanumerica) else '' end),
		@cui = max(case when parametru='CODFISC' then rtrim(val_alfanumerica) else '' end),
		@ordreg = max(case when parametru='ORDREG' then rtrim(val_alfanumerica) else '' end),
		@jud = max(case when parametru='JUDET' then rtrim(val_alfanumerica) else '' end),
		@adresa = max(case when parametru='ADRESA' then rtrim(val_alfanumerica) else '' end),
		@ct = max(case when parametru='CONTBC' then rtrim(val_alfanumerica) else '' end),
		@banca = max(case when parametru='BANCA' then rtrim(val_alfanumerica) else '' end),
		@email = max(case when parametru='EMAIL' then rtrim(val_alfanumerica) else '' end)
	from par WHERE tip_parametru = 'GE' AND parametru in ('NUME','CODFISC','ORDREG','JUDET','ADRESA','CONTBC','BANCA','EMAIL')
	
	set @ion = isnull((SELECT rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'ID' AND parametru = rtrim(host_id()) + 'N'), 
			(select rtrim(nume) from utilizatori where id=@utilizator))
	set @cnp = isnull((SELECT rtrim(left(val_alfanumerica, 13)) FROM par WHERE tip_parametru = 'ID' AND parametru = rtrim(host_id()) + 'C'), 
					dbo.wfProprietateUtilizator(@utilizator, 'CNP'))

	/** Selectul principal	**/
	SELECT 
	row_number() OVER (partition by pz.factura, d.data_facturii order  by pz.factura, d.data_facturii) [NRCRT],
	row_number() OVER (order  by pz.factura, d.data_facturii) [numarrand],
	rtrim(convert(CHAR(10), pz.data_facturii, 104) + pz.factura) AS [OBIECTIDDOC], 
	@unitate [UNITATE], 
	RTRIM(t.Adresa) AS [ADRESA],	
	@cui	[CUI],  
	@ordreg	[ORDREG],
	@jud	[JUD],  
	@adresa	[ADR],  
	@ct	[CT], 
	@email [EMAIL],
	@banca	[BC], 
	rtrim(pz.cota_tva) AS [PROCTVA],
	rtrim(isnull(it.observatii, '')) AS [FURNIZ],				
	rtrim(CASE d.gestiune_primitoare WHEN '' THEN rtrim(isnull(l.oras,rtrim(t.localitate)) + ',' + LTRIM(LEFT(t.adresa, 20))) ELSE '' END) AS [ADRSED], 
	rtrim(t.denumire) AS [TERT1],
	rtrim(t.denumire) AS [TERT], 
	rtrim(it.banca3) AS [ORCC],	
	rtrim(it2.descriere) AS [PCTL],
	rtrim(j.denumire) AS [JUDETT],		
	rtrim(t.cod_fiscal) AS [CODFISCT], 
	rtrim(isnull(l.oras, t.localitate) + ',' + LTRIM(LEFT(t.adresa, 20))) AS [ADRESAT], 		
	rtrim(CASE d.gestiune_primitoare WHEN '' THEN '' 
	ELSE isnull(rtrim(ISNULL((		SELECT oras
									FROM localitati
									WHERE cod_oras = it.pers_contact
									), it.pers_contact)) + ',' + rtrim(ltrim(it.e_mail)) + ', jud. ' + ltrim(ISNULL((
									SELECT denumire
									FROM judete
									WHERE cod_judet = it.telefon_fax2
									), it.telefon_fax2)), rtrim(isnull(
									l.oras, t.localitate)) + ',' +LTRIM(LEFT(t.adresa, 20))) END) AS [ADRPCL],
	rtrim(pz.Factura) AS [FACTURA], 
	rtrim(convert(CHAR(10), pz.data, 103)) AS [DATA],
	rtrim(convert(CHAR(10), d.data_facturii, 103)) AS [DATAFACTURII],
	rtrim(t.judet) AS	[JUDET], 
	rtrim(pz.numar) AS [AVIZ], 
	rtrim(t.cont_in_banca) AS [CONTT], 
	rtrim(t.banca) AS [BANCAT], 
	rtrim(pz.contract) AS [COMANDA], 
	rtrim(ltrim(convert(CHAR(19), convert(MONEY, round(pz.cantitate * pz.pret_valuta * pz.cota_tva / 100, 2), 1)))) [TVA],
	rtrim((CASE WHEN n.tip = 'F' THEN mf.Denumire WHEN pz.barcod = '' OR 1 = 1 THEN n.denumire else ns.Denumire END)) AS [DEN], 
	rtrim(ISNULL(( ltrim(rtrim(cb.cod_de_bare))) + ',', '') + ltrim(rtrim(pz.cod_intrare))) AS [CODBARE], 
	rtrim(n.um) AS [UM],
	rtrim((CASE WHEN pz.barcod = ''OR 1 = 0 THEN n.um ELSE n.um_1 END)) AS [UMASURA],			
	rtrim(convert(CHAR(13), convert(MONEY, round(pz.pret_valuta, 2)), 1)) AS [PRET],
	RTRIM(lTRIM(convert(CHAR(20), convert(MONEY, round(pz.cantitate * pz.pret_valuta, 2), 1)))) [VAL],
	rtrim(ltrim(isnull(d.TVAPOZ,''))) as TVAPOZ,
	rtrim(convert(CHAR(10), convert(MONEY, round(pz.cantitate, 3), 1))) AS [CANT], 
	rtrim(pz.discount) AS [DISC],
	@ion [ION],
	rtrim(substring(af.OBSERVATII, 1, 50)) AS [OBSERVATII],
	rtrim(ltrim(ISNULL(d.GRNETA,''))) [GRNETA],
	rtrim(CONVERT(CHAR(10), pz.data_scadentei, 103)) AS [SCADENTA], 
	RTRIM(LTRIM(isnull(d.TFDISC,''))) AS [TFDISC],
	@cnp [CNP],
	rtrim(af.numele_delegatului) AS [DELEG], 
	rtrim(convert(CHAR(15), convert(MONEY, round(d.valoare, 2 ),1))) AS [TOTAL],
	rtrim(convert(CHAR(15), convert(MONEY, round((d.tva_22), 2)), 1)) AS [TVATOTAL], 
	RTRIM(LTRIM(isnull(d.DISCOUNT,''))) AS [DISCOUNT], 
	RTRIM(ltrim(isnull(d.VALFDISC,''))) as[VALFDISC],
	RTRIM(ltrim(isnull(d.TVAFDISC,''))) as [TVAFDISC],
	RTRIM(ltrim(isnull(d.VALDISC,''))) [VALDISC], 
	RTRIM(ltrim(isnull(d.TVADISC,'')))  as [TVADISC], 					
	rtrim(af.seria_buletin) AS [CIS], 
	rtrim(af.numar_buletin) AS [CI], 
	rtrim(af.eliberat) AS [POLITIA], 
	rtrim(convert(CHAR(15), convert(MONEY, round(d.Valoare+d.Tva_22, 2)), 1)) AS [TOTALTVA], 
	rtrim(af.mijloc_de_transport) AS [AUTO], 
	rtrim(CONVERT(CHAR(10), af.data_expedierii, 103)) AS [DATAE], 
	rtrim(left(af.ora_expedierii, 2) + ':' + substring(af.ora_expedierii, 3, 2)) AS [ORA]	
	into #selectMare
	FROM 
	#PozDocFiltr pz
	INNER JOIN #DocFiltr d on d.factura=pz.factura and d.Data_facturii=pz.Data_facturii
	LEFT JOIN terti t on t.Tert=pz.Tert and t.Subunitate=@Subunitate
	LEFT JOIN nomencl n on n.Cod=pz.Cod
	LEFT JOIN anexafac af on af.subunitate=@subunitate and af.numar_factura=pz.factura
	LEFT JOIN localitati l on t.localitate=l.cod_oras
	LEFT JOIN infotert it on it.tert=t.tert and it.subunitate=@subunitate and it.identificator=''
	LEFT JOIN infotert it2 on it2.tert=pz.tert and it2.subunitate=@subunitate AND it2.identificator = substring(pz.numar_DVI, 14, 5)
	LEFT JOIN judete j on t.judet=j.cod_judet
	LEFT JOIN mfix mf on mf.numar_de_inventar = pz.cod_intrare
	LEFT JOIN nomspec ns on  pz.barcod = ns.cod_special AND pz.cod = ns.cod and pz.tert = ns.tert
	cross apply (select max(Cod_de_bare) Cod_de_bare from codbare cb where cb.Cod_produs=n.cod) cb
	--LEFT JOIN codbare cb on cb.cod_produs=n.cod
	ORDER BY pz.data_facturii, pz.factura

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY datafacturii,factura,NRCRT
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formFacturaSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formFacturaSP1')
	begin
		exec formFacturaSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (formFactura)'
	raiserror(@mesaj, 11, 1)
end catch
