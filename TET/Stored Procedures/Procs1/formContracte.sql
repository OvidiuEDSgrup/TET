--***
CREATE PROCEDURE formContracte @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @utilizator varchar(50), @subunitate varchar(20), @tip varchar(2), @contract varchar(20), @tert varchar(20), @data datetime, @unitate varchar(100),
	@sediu VARCHAR(100), @cui VARCHAR(100), @ordreg VARCHAR(100), @jud VARCHAR(100), @adresa varchar(100), @numar varchar(20), @contbc varchar(20), @banca varchar(50),
	@mesaj varchar(1000), @cTextSelect nvarchar(max), @debug bit
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
-- declaratii variabile
-- citire filtre
	/** Filtre **/
	SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')
	set @contract=@parXML.value('(/*/@numar)[1]', 'varchar(20)')
	set @data=@parXML.value('(/*/@data)[1]', 'datetime')
	set @tert=@parXML.value('(/*/@tert)[1]', 'varchar(20)')

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

-- prefiltrare con
	
	IF OBJECT_ID('tempdb..#conFiltr') IS NOT NULL
		DROP TABLE #conFiltr
		
	CREATE TABLE [dbo].[#conFiltr]([Contract] [varchar](20) NOT NULL,[Tert] [varchar](13) NOT NULL,
		[Punct_livrare] [varchar](13) NOT NULL,[Data] [datetime] NOT NULL,[Stare] [varchar](1) NOT NULL,[Loc_de_munca] [varchar](9) NOT NULL,[Gestiune] [varchar](9) NOT NULL,
		[Termen] [datetime] NOT NULL,[Scadenta] [smallint] NOT NULL,[Discount] [real] NOT NULL,[Valuta] [varchar](3) NOT NULL,[Curs] [float] NOT NULL,
		[Mod_plata] [varchar](1) NOT NULL,[Mod_ambalare] [varchar](1) NOT NULL,[Factura] [varchar](20) NOT NULL,[Total_contractat] [float] NOT NULL,
		[Total_TVA] [float] NOT NULL,[Contract_coresp] [varchar](20) NOT NULL,[Mod_penalizare] [varchar](13) NOT NULL,[Procent_penalizare] [real] NOT NULL,
		[Procent_avans] [real] NOT NULL,[Avans] [float] NOT NULL,[Nr_rate] [smallint] NOT NULL,[Val_reziduala] [float] NOT NULL,
		[Sold_initial] [float] NOT NULL,[Cod_dobanda] [varchar](20) NOT NULL,[Dobanda] [real] NOT NULL,[Incasat] [float] NOT NULL,[Responsabil] [varchar](20) NOT NULL,
		[Responsabil_tert] [varchar](20) NOT NULL,[Explicatii] [varchar](50) NOT NULL,[Data_rezilierii] [datetime] NOT NULL
		)
	
	insert into #conFiltr(Contract, Tert, Punct_livrare, Data, Stare, Loc_de_munca, Gestiune, Termen, Scadenta, Discount, Valuta, Curs, 
		Mod_plata, Mod_ambalare, Factura, Total_contractat, Total_TVA, Contract_coresp, Mod_penalizare, Procent_penalizare, Procent_avans, Avans, 
		Nr_rate, Val_reziduala, Sold_initial, Cod_dobanda, Dobanda, Incasat, Responsabil, Responsabil_tert, Explicatii, Data_rezilierii
	)

	select Contract, Tert, Punct_livrare, Data, Stare, Loc_de_munca, Gestiune, Termen, Scadenta, Discount, Valuta, Curs, 
		Mod_plata, Mod_ambalare, Factura, Total_contractat, Total_TVA, Contract_coresp, Mod_penalizare, Procent_penalizare, Procent_avans, Avans, 
		Nr_rate, Val_reziduala, Sold_initial, Cod_dobanda, Dobanda, Incasat, Responsabil, Responsabil_tert, Explicatii, Data_rezilierii
	from con
	where con.Subunitate = @subunitate 
		and con.Tip = 'FA'
		and (@contract = '' or con.Contract = @contract)
		and (@data = '' or con. Data = @data)
		and (@tert = '' or con.Tert = @tert)


	IF OBJECT_ID('tempdb..#pozconFiltr') IS NOT NULL
		DROP TABLE #conFiltr
		
--prefiltrare pozcon
	CREATE TABLE [dbo].[#pozconFiltr]([Contract] [varchar](20) NOT NULL,[Tert] [varchar](13) NOT NULL,[Punct_livrare] [varchar](13) NOT NULL,
		[Data] [datetime] NOT NULL,[Cod] [varchar](20) NOT NULL,[Cantitate] [float] NOT NULL,[Pret] [float] NOT NULL,
		[Pret_promotional] [float] NOT NULL,[Discount] [real] NOT NULL,[Termen] [datetime] NOT NULL,
		[Factura] [varchar](9) NOT NULL,[Cant_disponibila] [float] NOT NULL,[Cant_aprobata] [float] NOT NULL,
		[Cant_realizata] [float] NOT NULL,[Valuta] [varchar](3) NOT NULL,[Cota_TVA] [real] NOT NULL,[Suma_TVA] [float] NOT NULL,
		[Mod_de_plata] [varchar](8) NOT NULL,[UM] [varchar](1) NOT NULL,[Zi_scadenta_din_luna] [smallint] NOT NULL,
		[Explicatii] [varchar](200) NOT NULL,[Numar_pozitie] [int] NOT NULL,[Utilizator] [varchar](10) NOT NULL,
		[Data_operarii] [datetime] NOT NULL,[Ora_operarii] [varchar](6) NOT NULL
	)	
	
	insert into #pozconFiltr (Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional, Discount, Termen, Factura, Cant_disponibila, 
		Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, Suma_TVA, Mod_de_plata, UM, Zi_scadenta_din_luna, Explicatii, Numar_pozitie, 
		Utilizator, Data_operarii, Ora_operarii)
		
	select Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional, Discount, Termen, Factura, Cant_disponibila, 
		Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, Suma_TVA, Mod_de_plata, UM, Zi_scadenta_din_luna, Explicatii, Numar_pozitie, 
		Utilizator, Data_operarii, Ora_operarii	
	from Pozcon p
	where p.Subunitate = @subunitate
		and p.Tip = 'FA'
		and (@contract = '' or p.Contract = @contract)
		and (@data = '' or p.Data = @data)
		and (@tert = '' or p.Tert = @tert)

	
	SELECT @unitate = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'
	SELECT @cui = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CODFISC'
	SELECT @contbc = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'CONTBC'
	select @jud = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'JUDET'
	select @sediu = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'SEDIU'
	select @adresa = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'ADRESA'
	select @banca = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'BANCA'
	
-- select-ul propriu-zis si optimizari 
	
	select @unitate UNITATE, @sediu LOCALITATE, @cui CUI, @adresa ADR, @jud JUDET, @contbc CONT, @banca as BANCA,
	ltrim(c.contract) as NRCOM, t.denumire as FRZ,
	t.adresa as ADRESATERT, t.localitate as LOCTERT, t.judet as JUDTERT,
	t.cont_in_banca as CONTTERT, t.banca as BANCATERT,
	convert(CHAR(10),c.data,103) as DATA,
	row_number() OVER (ORDER BY pc.cod)  as NRCRT,
	pc.cod AS COD,
	n.denumire as DEN,
	n.um as UM,
	left(convert(char(16),convert(money,round(pc.cantitate,2)),2),15) as CANT,
	left(convert(char(16),convert(money,round(pc.pret,2)),2),15) as PRET,
	convert(char(15),convert(money,round(pc.pret*pc.cantitate,2)),1) as VAL,
	convert(char(10),pc.termen,104) as TERMEN,
	convert(char(15),convert(money,round((select sum(p.pret*p.cantitate) from #pozconFiltr p where p.data=pc.data and p.contract=pc.contract and p.tert=pc.tert),2)),1) as TOTAL
	
	into #selectMare
	from #conFiltr c
	left join #pozconFiltr pc on pc.contract=c.contract and pc.data=c.data and pc.tert=c.tert
	left join terti t on t.tert=c.tert and t.subunitate = @subunitate
	left join nomencl n on n.cod=pc.cod


	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY DATA, NRCOM, NRCRT
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formContracteSP1')
	begin
		exec formContracteSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+ ' (formContracte)'
	raiserror(@mesaj, 11, 1)
end catch
