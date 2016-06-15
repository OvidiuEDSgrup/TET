/**
	Procedura de luare a datelor pentru formularul web (rdl) "Receptie pret amanunt PDF"

**/
create procedure rapFormReceptieAm @sesiune varchar(50), @tip varchar(2), @numar varchar(20), @data datetime
as
begin try 
set transaction isolation level read uncommitted
	declare 
		@subunitate varchar(10), @locm varchar(50), @px xml,
		@gestiune varchar(20), @factura varchar(20), @grupaTerti varchar(20),
		@utilizator varchar(50), @filtruFacturi bit, @detalii xml, @xmlDate xml

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	if object_id('tempdb..#PozDocFiltr') is not null
		drop table #PozDocFiltr

	/** Pregatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	create table [dbo].[#PozDocFiltr] ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_valuta] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, 
		[Pret_cu_amanuntul] [float] NOT NULL, [TVA_deductibil] [float] NOT NULL, [TVA_neexigibil] [real] NOT NULL,
		[Tert] [varchar](13) NOT NULL, [Factura] [varchar](20) NOT NULL,
		[Data_facturii] [datetime] NOT NULL, [numar_pozitie] [int], [Utilizator] [varchar](200)
		)

	insert into #PozDocFiltr (		
		Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Pret_cu_amanuntul, 
		TVA_deductibil, tva_neexigibil, Tert, Factura, Data_facturii, Numar_Pozitie, Utilizator
		)
	select
		rtrim(Numar), rtrim(Cod), data, rtrim(Gestiune), Cantitate, Pret_valuta, Pret_de_stoc, 
		Pret_cu_amanuntul, TVA_deductibil, tva_neexigibil, rtrim(pz.Tert), rtrim(Factura), Data_facturii, Numar_pozitie,
		rtrim(Utilizator)
	from pozdoc pz
	where pz.subunitate = @subunitate
		and pz.tip = @tip
		and pz.data = @data
		and pz.Numar = @numar
	
	create index IX1 on #pozdocfiltr(factura,data_facturii)
	create index IX2 on #pozdocfiltr(cod)
	create index IX3 on #pozdocfiltr(cantitate, pret_valuta)

	select top 1 @detalii = detalii, @locm = RTRIM(Loc_munca) from doc where tip = @tip and numar = @numar and data = @data

	/** Datele despre firma se vor stoca de acuma incolo in tabela #dateFirma */
	IF OBJECT_ID('tempdb.dbo.#dateFirma') IS NOT NULL DROP TABLE #dateFirma
	CREATE TABLE #dateFirma(locm varchar(50))
	exec wDateFirma_tabela
	EXEC wDateFirma @locm = @locm

	/** Pentru documentele nou create, daca nu se seteaza datele de formular prin operatie, se vor lua datele gestiunii. */
	if @detalii is null or @detalii.exist('(/row/@gestionar)[1]') = 0
	begin
		select top 1 @gestiune = rtrim(Cod_gestiune) from doc where tip = @tip and numar = @numar and data = @data
		select top 1 @detalii = detalii from gestiuni where cod_gestiune = @gestiune
		set @xmlDate =
		(
			select @tip as tip, @numar as numar, @data as data,
			(
				select @detalii
				for xml raw('detalii'), type
			)
			for xml raw('parametri')
		)

		exec wOPDateFormular @sesiune = @sesiune, @parXML = @xmlDate
		select top 1 @detalii = detalii from doc where tip = @tip and numar = @numar and data = @data
	end

	create table #preturi(cod varchar(20))
	exec CreazaDiezPreturi

	insert into #preturi (cod)
	select pz.cod
	from #PozDocFiltr pz
	group by pz.cod

	select @px = (select @gestiune as gestiune, CONVERT(varchar(10), @data, 101) as data for xml raw)
	exec wIaPreturi @sesiune = @sesiune, @parXML = @px

	update pz
		set pz.Pret_cu_amanuntul = (case when g.Tip_gestiune = 'C' then isnull(pp.pret_amanunt, 0) else pz.Pret_cu_amanuntul end)
	from #PozDocFiltr pz
	left join gestiuni g on pz.gestiune = g.cod_gestiune and g.Subunitate = @Subunitate
	left join #preturi pp on pp.cod = pz.cod

	/** selectul principal	**/
	select
		df.firma as UNITATE, df.codFiscal as CUI, df.ordreg as ORDREG, df.cont as CONT, df.banca as BANCA,
		df.judet as JUDET, df.sediu as LOCALITATE,
		convert(varchar(10), pz.data, 103) as DATA,
		ltrim(pz.numar) as DOC,
		row_number() over (order by pz.numar_pozitie) as NR,
		rtrim(pz.cod) as COD,
		ltrim(rtrim(g.denumire_gestiune)) as GEST,
		rtrim(ltrim(t.denumire)) as FURN,
		rtrim(ltrim(pz.factura)) as FACT,
		convert(varchar(10), pz.Data_facturii, 103) as DATA_FACTURII,
		rtrim(n.denumire) as DENUMIRE,
		rtrim(n.um) as UM,
		pz.pret_de_stoc as PRET,
		round(pz.cantitate, 2) as CANT,
		round(pz.pret_de_stoc * pz.cantitate, 2) as VAL,
		round(pz.TVA_deductibil, 2) as TVA,
		round((select sum(p.pret_de_stoc * p.cantitate) from #PozDocFiltr p where p.data = pz.data and p.numar = pz.numar), 2) as TVAL,
		round((select sum(p.TVA_deductibil) from #PozDocFiltr p where p.numar = pz.numar and p.data = pz.data), 2) as TTVA,
		round((select (sum(p.pret_de_stoc * p.cantitate) + sum(p.TVA_deductibil)) from #PozDocFiltr p where p.numar = pz.numar and p.data = pz.data), 2) as TOTAL,
		isnull(@detalii.value('(/row/@denmembru1)[1]', 'varchar(150)'), '') as MEMBR1, /** doc.detalii */
		isnull(@detalii.value('(/row/@denmembru2)[1]', 'varchar(150)'), '') as MEMBR2,
		isnull(@detalii.value('(/row/@denmembru3)[1]', 'varchar(150)'), '') as MEMBR3,
		isnull(@detalii.value('(/row/@denmembru4)[1]', 'varchar(150)'), '') as MEMBR4,
		isnull(@detalii.value('(/row/@observatii)[1]', 'varchar(300)'), '') as OBSERVATII,
		isnull(@detalii.value('(/row/@gestionar)[1]', 'varchar(50)'), '') AS gestionar,
		isnull(@detalii.value('(/row/@dengestionar)[1]', 'varchar(150)'), '') AS dengestionar,
		'Operat: ' + rtrim (pz.utilizator) + '. Tiparit la ' + convert(varchar(10), getdate(), 103) + ' ' + convert(varchar(5), getdate(), 108)
			+ ', de catre ' + @utilizator as date_tiparire,

		-- pentru receptii in pret cu amanuntul
		round(n.pret_cu_amanuntul, 2) as PRETV,
		round(n.pret_cu_amanuntul * pz.cantitate, 2) as VALPV,
		round(pz.cantitate * (pz.pret_cu_amanuntul/(1 + convert(decimal(12,3), pz.tva_neexigibil)/100) - pz.pret_de_stoc), 2) as AD,
		round(pz.pret_cu_amanuntul, 2) as PRAM,
		round(pz.pret_cu_amanuntul * pz.cantitate, 2) as VALAM,
		round((select sum(p.cantitate) from #pozdocFiltr p), 2) as TCANT,
		round((select sum(round(p.cantitate * round((p.pret_cu_amanuntul/(1 + convert(decimal(12,3), p.tva_neexigibil)/100) - p.pret_de_stoc), 3), 2)) from #pozdocFiltr p), 2) as TAD,
		round((select sum(round(p.pret_cu_amanuntul * p.cantitate, 2)) from #pozdocFiltr p), 2) as TOTALA,
		rtrim((case when exists (select 1 from par where tip_parametru = 'GE' and parametru = 'LOCTERTI' and val_logica = 1) then (select max(oras) from localitati loc where loc.cod_judet = t.judet and loc.cod_oras = t.localitate) else t.localitate end)) as LOC,
		rtrim((case when exists (select 1 from par where tip_parametru = 'GE' and parametru ='JUDTERTI ' and val_logica = 1) then (select max(denumire) from judete jud where jud.cod_judet = t.judet) else t.judet end)) as JUD,
		round((select sum(round(p.pret_de_stoc * p.cantitate, 2)) from #pozdocFiltr p), 2) as TVPA,
		pz.numar_pozitie AS ordine
	into #date
	from #PozDocFiltr pz
	left join terti t on t.Tert = pz.Tert and t.Subunitate = @Subunitate
	left join nomencl n on n.Cod = pz.Cod
	left join gestiuni g on pz.gestiune = g.cod_gestiune and g.subunitate = @subunitate
	left join #dateFirma df ON 1 = 1

	if exists (select 1 from sys.sysobjects where name = 'rapFormReceptieAmSP')
		exec rapFormReceptieAmSP @sesiune = @sesiune, @tip = @tip, @numar = @numar, @data = @data
	
	select * from #date order by ordine

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
