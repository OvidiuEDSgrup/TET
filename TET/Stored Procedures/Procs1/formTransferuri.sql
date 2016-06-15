/**
	Formularul este folosit pentru a lista Transferuri. 

**/
CREATE PROCEDURE formTransferuri @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE 
		@firma VARCHAR(100), @adr VARCHAR(100), @cui VARCHAR(100), @ordreg VARCHAR(100), @jud VARCHAR(100), @loc varchar(100), @cont VARCHAR(100), 
		@banca varchar(100), @tip varchar(2), @numar varchar(20), @cnp varchar(15),
		@mesaj varchar(1000), @subunitate varchar(10), @data datetime, @cTextSelect nvarchar(max), @debug bit, 
		@gestiune varchar(20), @utilizator varchar(50)
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	/** Filtre **/
	SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @numar=@parXML.value('(/*/@numar)[1]', 'varchar(20)')
	SET @data= @parXML.value('(/*/@data)[1]', 'datetime')
			
	/* Alte **/
	
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	IF OBJECT_ID('tempdb..#PozDocFiltr') IS NOT NULL
		DROP TABLE #PozDocFiltr

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
	SELECT rtrim(Numar), rtrim(Cod), max(Data) data, max(rtrim(Gestiune)), sum(Cantitate), max(Pret_valuta), max(Pret_de_stoc), 
		MAX(Adaos), max(Pret_vanzare), max(Pret_cu_amanuntul), sum(TVA_deductibil), max(Cota_TVA), rtrim(Cod_intrare), 
		MAX(rtrim(Locatie)), max(Data_expirarii), max(Loc_de_munca), max(rtrim(Comanda)), max(rtrim(Barcod)), 
		max(Discount), max(rtrim(pz.Tert)), rtrim(Factura), max(rtrim(Gestiune_primitoare)), max(Numar_DVI), max(Valuta), 
		max(Curs), max(Data_facturii), max(Data_scadentei), MAX(rtrim(Contract))
	FROM pozdoc pz
	
	WHERE pz.subunitate = @subunitate
		AND pz.tip = 'TE'
		AND pz.data = @data
		and pz.numar = @numar
	group by pz.numar, pz.cod, pz.factura, pz.cod_intrare

	create index IX1 on #pozdocfiltr(numar,cod,cod_intrare)
	create index IX2 on #pozdocfiltr(cod)
	
	/**
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
	SELECT @firma = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'
	SELECT @cui = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CODFISC'
	SELECT @ordreg = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ORDREG'
	select @jud= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'JUDET'
	select @loc= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'SEDIU'
	select @adr=rtrim( val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ADRESA'
	select @cont=rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CONTBC'
	select @banca= rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'BANCA'
	select @cnp= left(val_alfanumerica,13) from par where tip_parametru='ID' and parametru=rtrim(host_id())+'C'
	
	/** Daca tipul gestiunii primitoare este de tip custodie vom incerca sa aducem datele tertului din locatie */
	IF OBJECT_ID('tempdb..#custodie_tert') IS NOT NULL
		drop table #custodie_tert
	create table #custodie_tert(
		locatie varchar(20),
		tert varchar(20), dentert varchar(100), punct_livr varchar(20), adr_punct varchar(100), nrord varchar(200),
		cui varchar(20), sediu varchar(100), judet varchar(100), cont varchar(100), banca varchar(200))
	declare 
		@gest varchar(20), @locatie varchar(20)
	select top 1 @gest=Gestiune_primitoare, @locatie = locatie from #PozDocFiltr
	IF (select top 1 ISNULL(detalii.value('(/*/@custodie)[1]','bit'),0) from gestiuni where Cod_gestiune=@gest)=1
	begin
		insert #custodie_tert (locatie,tert, dentert, punct_livr, adr_punct,nrord, cui,sediu,judet,cont, banca)
		select
			top 1 
			@locatie,rtrim(t.tert), rtrim(t.denumire), ISNULL(it.Identificator,''), ISNULL(it.e_mail,''),rtrim(it2.banca3), rtrim(t.Cod_fiscal), rtrim(t.Adresa), 
			ISNULL(j.denumire, t.judet), rtrim(t.Cont_in_banca), rtrim(t.Banca)
		from terti t
		LEFT join infotert it on t.tert=it.tert	and t.Subunitate='1' and it.Identificator=SUBSTRING (@locatie, 14, 5) and it.Identificator<>'' and it.Subunitate='1'
		LEFT JOIN infotert it2 on it2.Tert=t.tert and it2.Identificator='' and it2.Subunitate='1'
		LEFT JOIN Judete j on j.cod_judet=t.Judet
		where t.Tert= LEFT(@locatie,13)
	end

	/** Selectul principal	**/
	SELECT
	@firma as firma, @cui as cif, @ordreg as ordreg, @jud as jud, @loc as loc, @adr as adr, @cont as cont, @banca as banca, 
	pz.numar as NUMAR, pz.data as data, 
	rtrim(g.denumire_gestiune) as predator,
	rtrim(ge.denumire_gestiune) as primitor,
	(select valoare from proprietati pr where pr.Cod = pz.Gestiune and cod_proprietate='ADRGEST') as ADRESAPRD,
	(select valoare from proprietati pr where pr.Cod = pz.Gestiune_primitoare and cod_proprietate='ADRGEST') as ADRESAPRM,
	row_number() OVER(ORDER BY pz.cod) as nrcrt,
	rtrim(pz.cod)+'-'+n.denumire as explicatie,
	n.um as UM,
	left(convert(char(14),convert(money,round(pz.cantitate,3)),2),13) as CANT,
	left(convert(char(17),convert(money,round(pz.pret_cu_amanuntul,2)),2),16) as PRET,
	convert(char(16),convert(money,round(pz.cantitate*pz.pret_cu_amanuntul,2)),1) as VALOARE,
	convert(char(17),convert(money,round((select sum(p.pret_cu_amanuntul*p.cantitate) from #pozdocfiltr p where p.data=pz.data and p.numar=pz.numar),2)),1) as total,
	rtrim(a.observatii) as OBSERVATII,
	rtrim(a.numele_delegatului) as NUMEDELEGAT,
	rtrim(a.seria_buletin) as sr,
	rtrim(a.numar_buletin) as nrbi,
	rtrim(a.eliberat) as ELIB,
	rtrim(a.mijloc_de_transport) as MIJLOCTRANSP,
    'CNP: '+@cnp as cnp,
    rtrim(a.numarul_mijlocului) as nrmij,
	convert(CHAR(10),getdate(),103) as dataexp,
	left(a.ora_expedierii,2)+':'+substring(a.ora_expedierii,3,2) as ORAEXP,
	rtrim(ltrim(a.numele_delegatului)) as com1,
	rtrim(ltrim(ax.eliberat)) as com2,
	rtrim(ltrim(a.mijloc_de_transport)) as com3,
	rtrim(ltrim(a.observatii)) as com4,

	/** Informatii pentru custodie terti */
	ISNULL(ct.banca,'') [BANCATERT],
	ISNULL(ct.cont,'') [CONTTERT],
	ISNULL(ct.punct_livr,'') [PUNCTLIVRTERT],
	ISNULL(ct.cui,'') [CUITERT],
	ISNULL(ct.dentert,'') [TERT],
	ISNULL(ct.adr_punct,'') [ADRPUNCT],
	ISNULL(ct.sediu,'') [SEDIUTERT],
	ISNULL(ct.judet,'') [JUDETTERT],
	ISNULL(ct.nrord,'') [NRORDTERT]
	into #selectMare
	FROM 
	#PozDocFiltr pz
	--LEFT JOIN terti t on t.Tert=pz.Tert and t.Subunitate=@Subunitate
	LEFT JOIN nomencl n on n.Cod=pz.Cod
	left join gestiuni g on pz.gestiune = g.cod_gestiune and g.Subunitate=@Subunitate
	left join gestiuni ge on pz.gestiune_primitoare =  ge.cod_gestiune and ge.Subunitate=@Subunitate
	left join anexadoc a on a.tip='TE' and pz.numar =  a.numar and pz.data = a.data and a.Subunitate=@Subunitate
	left join anexadoc ax on ax.tip = 'TD' and pz.numar =  ax.numar and pz.data = ax.data and ax.Subunitate=@Subunitate
	left join #custodie_tert ct on ct.locatie=pz.Locatie
			
	
	ORDER BY pz.data, pz.numar

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY data,numar,NRCRT
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formTransferuriSP1')
	begin
		exec formTransferuriSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (formTransferuri)'
	raiserror(@mesaj, 11, 1)
end catch
