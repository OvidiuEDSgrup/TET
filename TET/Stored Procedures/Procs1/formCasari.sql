/**
	Formularul este folosit pentru a lista casari. 

**/
CREATE PROCEDURE formCasari @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @firma VARCHAR(100), @tip varchar(2), @numar varchar(20),
		@mesaj varchar(1000), @subunitate varchar(10), @data datetime, @cTextSelect nvarchar(max), @debug bit, 
		@gestiune varchar(20), @utilizator varchar(50)
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	/** Filtre **/
	SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @numar=@parXML.value('(/*/@numar)[1]', 'varchar(20)')
	SET @data= @parXML.value('(/*/@data)[1]', 'datetime')
	SET @gestiune= isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),'')
		
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
		[Gestiune_primitoare] [varchar](40) NOT NULL, [Numar_DVI] [varchar](25) NOT NULL, [Valuta] [varchar](3) NOT NULL, [Curs] [float] NOT NULL, 
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
		AND pz.tip = 'CI'
		AND pz.data = @data
		and pz.numar = @numar
	group by pz.numar, pz.cod, pz.factura, pz.cod_intrare

	create index IX1 on #pozdocfiltr(numar,cod,cod_intrare)
	
	/**
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
	SELECT @firma = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'
	
	/** Selectul principal	**/
	SELECT
	@firma as UNITATE,
	ltrim(pz.gestiune) as PRED,
	ltrim(pz.numar) as DOC,
	ltrim(pz.loc_de_munca) as lm,
	convert(char(12),pz.data,104) as data,
	row_number() OVER(ORDER BY pz.cod) as nr,
	rtrim(pz.cod_intrare) as CODI,
	pz.cod as COD,
	n.denumire as denumire,
	n.um as um,
	left(convert(char(16),convert(money,round(pz.cantitate,2)),2),15) as cant,
	left(convert(char(16),convert(money,round(pz.pret_de_stoc,2)),2),15) as pret,
	convert(char(15),convert(money,round(pz.pret_de_stoc*pz.cantitate,2)),1) as VALOARE,
	convert(char(15),convert(money,round((select sum(p.pret_de_stoc*p.cantitate) from #pozdocfiltr p),2)),1) as total

	into #selectMare
	FROM 
	#PozDocFiltr pz
	LEFT JOIN nomencl n on n.Cod = pz.Cod
	
	ORDER BY pz.data, pz.numar

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY data,DOC,NR
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formCasariSP1')
	begin
		exec formCasariSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (formCasari)'
	raiserror(@mesaj, 11, 1)
end catch
