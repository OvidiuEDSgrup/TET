--***
CREATE PROCEDURE formTransferMF @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @utilizator varchar(50), @subunitate varchar(20), @unitate varchar(100), @cTextSelect nvarchar(max), @debug bit, @mesaj varchar(1000), @tip varchar(3), @numar varchar(20), @data  datetime,
	@nrinv varchar(10)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

-- citire filtre
	/** Filtre **/
	SET @tip=@parXML.value('(/*/*/@tip)[1]', 'varchar(2)')
	SET @numar=@parXML.value('(/*/*/@numar)[1]', 'varchar(20)')
	set @data=@parXML.value('(/*/*/@data)[1]', 'datetime')
	SET @nrinv=@parXML.value('(/*/*/@nrinv)[1]', 'varchar(20)')

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	
	IF OBJECT_ID('tempdb..#misMFFiltr') IS NOT NULL
		DROP TABLE #misMFFiltr
	
	--prefitrare tabela misMF
	CREATE TABLE [dbo].[#misMFFiltr](
	[Data_lunii_de_miscare] [datetime] NOT NULL,[Numar_de_inventar] [varchar](13) NOT NULL,[Tip_miscare] [varchar](3) NOT NULL,
	[Numar_document] [varchar](8) NOT NULL,[Data_miscarii] [datetime] NOT NULL,[Tert] [varchar](13) NOT NULL,[Factura] [varchar](20) NOT NULL,
	[Pret] [float] NOT NULL,[TVA] [float] NOT NULL,[Cont_corespondent] [varchar](40) NOT NULL,[Loc_de_munca_primitor] [varchar](20) NOT NULL,[Gestiune_primitoare] [varchar](20) NOT NULL,
	[Diferenta_de_valoare] [float] NOT NULL,[Data_sfarsit_conservare] [datetime] NOT NULL,[Subunitate_primitoare] [varchar](40) NOT NULL,[Procent_inchiriere] [real] NOT NULL)
	
	insert into #misMFFiltr
	select max(Data_lunii_de_miscare), Numar_de_inventar, Tip_miscare, Numar_document, Data_miscarii, max(Tert), max(Factura), sum(Pret), sum(TVA), max(Cont_corespondent), 
		max(Loc_de_munca_primitor), max(Gestiune_primitoare), sum(Diferenta_de_valoare), max(Data_sfarsit_conservare), max(Subunitate_primitoare), max(Procent_inchiriere)
	from misMF 
	where misMF.subunitate = @subunitate 
		and 'M'+left(misMF.tip_miscare,1) = @tip 
		and (@numar='' or mismf.numar_document=@numar )
		and (@data='' or misMF.data_miscarii = @data )
		and (@nrinv='' or mismf.numar_de_inventar = @nrinv)
	group by misMF.numar_de_inventar, mismf.tip_miscare, mismf.numar_document, data_miscarii
	
	select * from #misMFFiltr
	
	SELECT @unitate = rtrim(val_alfanumerica) FROM par WHERE tip_parametru = 'GE' AND parametru = 'NUME'

-- select-ul propriu-zis si optimizari
	
	select @unitate as DENFIRMA,
		ltrim(m.numar_document) as NRDOC,
		convert(char(12),m.data_miscarii,104) as DATADOC,
		ltrim(m.factura) as NRFACT,
		rtrim(fisaMF.loc_de_munca)+' - '+isnull(lm.denumire, '') as LM, 
		rtrim(m.loc_de_munca_primitor)+' - '+isnull(lm1.denumire, '') as LMP,
		rtrim(fisaMF.gestiune)+' - '+isnull(left(g.denumire_gestiune,30), '') as GEST,
		rtrim(m.gestiune_primitoare)+' - '+isnull(left(g1.denumire_gestiune,30), '') as GESTP,
		LEFT(fisaMF.comanda,20)+' - '+isnull(comenzi.descriere, '') as COM,
		rtrim(fisamf.cont_mijloc_fix)+' - '+isnull(conturi.denumire_cont, '') as CONTD,
		rtrim(mfix.numar_de_inventar)+' - '+Mfix.denumire as DENMF,
		RTRIM(mfix.cod_de_clasificare) as CL,
		rtrim(convert(char(5),durata))+'  - ani' as DUR,
		ltrim(convert(char(15), convert(money, round(valoare_de_inventar,5)),1)) as VALINV,
		isnull(convert(char(12),a.data_expedierii,104),'') AS TERMEN,
		isnull(a.observatii,'') AS CONCLUZII,
		left(a.numele_delegatului,15) as COMISAR1,
		right(a.numele_delegatului,15) as COMISAR2,
		left(a.eliberat,15) as COMISAR3,
		right(a.eliberat,15) as COMISAR4
	
	into #selectMare
	from #misMFFiltr m
		left join MFix on m.numar_de_inventar = MFix.numar_de_inventar and MFix.subunitate = @subunitate 
		left join fisamf on m.data_lunii_de_miscare = fisamf.data_lunii_operatiei and fisamf.felul_operatiei=(case when left(m.tip_miscare,1)='I' then '3' when left(m.tip_miscare,1)='M' then '4' when left(m.tip_miscare,1)='E' then '5' when left(m.tip_miscare,1)='T' then '6' when left(m.tip_miscare,2)='CO' then '7' when left(m.tip_miscare,1)='S' then '8' else '9' end)
		left join anexadoc a on a.subunitate = @subunitate and a.numar = @numar and a.data = @data and a.tip=(case when m.tip_miscare='IAF' then '1' when m.tip_miscare='IPF' then '2' when m.tip_miscare='IPP' then '3' when m.tip_miscare='IDO' then '4' when m.tip_miscare='IAS' then '5' when m.tip_miscare='ISU' then '6' when m.tip_miscare='IAL' then '7' else @tip end)
		left join lm on fisaMF.loc_de_munca = lm.cod 
		left join lm lm1 on m.loc_de_munca_primitor = lm1.cod
		left join gestiuni g on fisamf.gestiune = g.cod_gestiune and g.subunitate = @subunitate
		left join gestiuni g1 on m.gestiune_primitoare = g1.cod_gestiune and g1.subunitate = @subunitate
		left join comenzi on comenzi.comanda = fisamf.comanda and comenzi.subunitate = @subunitate
		left join conturi on conturi.cont=fisamf.cont_mijloc_fix and conturi.subunitate = @subunitate 

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY DATADOC,NRFACT
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formTransferMFSP1')
	begin
		exec formTransferMFSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (formTransferMF)'
	raiserror(@mesaj, 11, 1)
end catch
