--***
create procedure rapFormTransferMF @sesiune varchar(50), @parXML xml, @numeTabelTemp varchar(100) = null output
as
begin try 
set transaction isolation level read uncommitted
	declare
		@utilizator varchar(50), @subunitate varchar(20), @unitate varchar(100),
		@tip varchar(3), @numar varchar(20), @data datetime, @nrinv varchar(10),
		@comandaSQL nvarchar(max)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	if len(@numeTabelTemp) > 0 --## nu se poate trimite in URL 
		set @numeTabelTemp = '##' + @numeTabelTemp
	
	if exists (select * from tempdb.sys.objects where name = @numeTabelTemp)
	begin 
		set @comandaSQL = 'select @parXML = convert(xml, parXML) from ' + @numeTabelTemp + '
		drop table ' + @numeTabelTemp
		exec sp_executesql @statement = @comandaSQL, @params = N'@parXML as xml output', @parXML = @parXML output
	end

	--
	-- filtre
	--

	set @tip = @parXML.value('(/*/*/@tip)[1]', 'varchar(2)')
	set @numar = @parXML.value('(/*/*/@numar)[1]', 'varchar(20)')
	set @data = @parXML.value('(/*/*/@data)[1]', 'datetime')
	set @nrinv = isnull(@parXML.value('(/*/*/@nrinv)[1]', 'varchar(20)'), '')

	if @nrinv = ''
		raiserror('Formularul trebuie apelat de pe o pozitie!', 16, 1)
		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	
	if object_id('tempdb..#misMFFiltr') is not null
		drop table #misMFFiltr
	
	--
	-- prefitrare tabela misMF
	--

	create table #misMFFiltr(
	[Data_lunii_de_miscare] [datetime] NOT NULL,[Numar_de_inventar] [varchar](13) NOT NULL,[Tip_miscare] [varchar](3) NOT NULL,
	[Numar_document] [varchar](8) NOT NULL,[Data_miscarii] [datetime] NOT NULL,[Tert] [varchar](13) NOT NULL,[Factura] [varchar](20) NOT NULL,
	[Pret] [float] NOT NULL,[TVA] [float] NOT NULL,[Cont_corespondent] [varchar](20) NOT NULL,[Loc_de_munca_primitor] [varchar](20) NOT NULL,[Gestiune_primitoare] [varchar](20) NOT NULL,
	[Diferenta_de_valoare] [float] NOT NULL,[Data_sfarsit_conservare] [datetime] NOT NULL,[Subunitate_primitoare] [varchar](40) NOT NULL,[Procent_inchiriere] [real] NOT NULL)
	
	insert into #misMFFiltr
	select max(Data_lunii_de_miscare), Numar_de_inventar, Tip_miscare, Numar_document, Data_miscarii, max(Tert), max(Factura), sum(Pret), sum(TVA), max(Cont_corespondent), 
		max(Loc_de_munca_primitor), max(Gestiune_primitoare), sum(Diferenta_de_valoare), max(Data_sfarsit_conservare), max(Subunitate_primitoare), max(Procent_inchiriere)
	from misMF 
	where misMF.subunitate = @subunitate 
		and 'M' + left(misMF.tip_miscare, 1) = @tip 
		and (@numar = '' or mismf.numar_document = @numar )
		and (@data = '' or misMF.data_miscarii = @data )
		and (@nrinv = '' or mismf.numar_de_inventar = @nrinv)
	group by misMF.numar_de_inventar, mismf.tip_miscare, mismf.numar_document, data_miscarii
	
	select @unitate = rtrim(val_alfanumerica) from par where tip_parametru = 'GE' and parametru = 'NUME'

	--
	-- select-ul propriu-zis
	--

	select 
		rtrim(@unitate) as DENFIRMA,
		rtrim(m.numar_document) as NRDOC,
		convert(varchar(10), m.data_miscarii, 103) as DATADOC,
		rtrim(m.factura) as NRFACT,
		rtrim(fisaMF.loc_de_munca)+' - '+isnull(rtrim(lm.denumire), '') as LM, 
		rtrim(m.loc_de_munca_primitor)+' - '+isnull(rtrim(lm1.denumire), '') as LMP,
		rtrim(fisaMF.gestiune) + ' - ' + isnull(left(g.denumire_gestiune, 30), '') as GEST,
		rtrim(m.gestiune_primitoare)+' - '+isnull(left(g1.denumire_gestiune,30), '') as GESTP,
		rtrim(left(fisaMF.comanda, 20)) + ' - ' + isnull(ltrim(rtrim(comenzi.descriere)), '') as COM,
		rtrim(fisamf.cont_mijloc_fix)+' - '+isnull(rtrim(conturi.denumire_cont), '') as CONTD,
		rtrim(mfix.numar_de_inventar)+' - ' + rtrim(Mfix.denumire) as DENMF,
		rtrim(mfix.cod_de_clasificare) as CL,
		convert(varchar(5), durata) + ' ani' as DUR,
		ltrim(rtrim(round(valoare_de_inventar, 5))) as VALINV,
		isnull(convert(varchar(10), a.data_expedierii, 103), '') AS TERMEN,
		isnull(a.observatii,'') AS CONCLUZII,
		left(a.numele_delegatului,15) as COMISAR1,
		right(a.numele_delegatului,15) as COMISAR2,
		left(a.eliberat,15) as COMISAR3,
		right(a.eliberat,15) as COMISAR4
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

	--
	-- SP1 pentru specifice de tratat
	--

	if exists (select 1 from sys.sysobjects where name = 'rapFormTransferMFSP1' and type = 'P')
	begin
		exec rapFormTransferMFSP1 @sesiune = @sesiune, @parXML = @parXML, @numeTabelTemp = @numeTabelTemp output
	end

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
