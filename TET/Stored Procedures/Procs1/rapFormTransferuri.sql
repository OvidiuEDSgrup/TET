/**
*	Procedura pentru Transferuri
*
*	Formularul este folosit pentru a lista Transferuri. 
*
**/
create procedure rapFormTransferuri @sesiune varchar(50), @numar varchar(20), @data datetime
as
begin try 
set transaction isolation level read uncommitted
	declare @locm varchar(50), @detalii xml, @delegat varchar(20), @tertDelegat varchar(20),
		@mesaj varchar(1000), @subunitate varchar(10), @tertCustodie varchar(100), @gestiuneCustodie varchar(50),
		@gestiune varchar(20), @tert varchar(20), @utilizator varchar(50), @detalii_gest varchar(100)
	
	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	if object_id('tempdb..#PozDocFiltr') is not null
		drop table #PozDocFiltr

	/** Pregatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	create table [dbo].[#PozDocFiltr] ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_formular] [float] NOT NULL, [Pret_cu_amanuntul] [float] NOT NULL, 
		[Cod_intrare] [varchar](13) NOT NULL, [Tert] [varchar](13) NOT NULL, [Gestiune_primitoare] [varchar](13) NOT NULL, [numar_pozitie] [int],
		[Locatie] [varchar](50), [Utilizator] [varchar](200)
		)

	insert into #PozDocFiltr (
		Numar, Cod, Data, Gestiune, Cantitate, Pret_formular, Pret_cu_amanuntul, 
		Cod_intrare, Tert, Gestiune_primitoare, numar_pozitie, Locatie, Utilizator
		)
	select 
		rtrim(Numar), rtrim(Cod), Data data, rtrim(Gestiune), Cantitate,
		Pret_de_stoc, Pret_cu_amanuntul, rtrim(Cod_intrare), rtrim(pz.Tert), rtrim(Gestiune_primitoare), Numar_pozitie,
		Locatie, rtrim(Utilizator)
	from pozdoc pz
	where pz.subunitate = @subunitate
		AND pz.tip = 'TE'
		AND pz.data = @data
		and pz.numar = @numar

	create index IX1 on #pozdocfiltr(numar,cod,cod_intrare)
	create index IX2 on #pozdocfiltr(cod)
	
	select top 1 @detalii = detalii, @locm = RTRIM(Loc_munca) from doc where tip = 'TE' and numar = @numar and data = @data

	/** Datele despre firma se vor stoca de acuma incolo in tabela #dateFirma */
	IF OBJECT_ID('tempdb.dbo.#dateFirma') IS NOT NULL DROP TABLE #dateFirma
	CREATE TABLE #dateFirma(locm varchar(50))
	exec wDateFirma_tabela
	EXEC wDateFirma @locm = @locm

	select @detalii_gest = (select rtrim(detalii.value('(/row/@dengestdest)[1]','varchar(100)'))
							from doc 
							where Subunitate = @subunitate and Tip = 'TE' and Data = @data and Numar = @numar)

	if isnull(@detalii_gest, '') = ''
		select @detalii_gest = (select rtrim(g.denumire_gestiune)
								from doc d
								inner join gestiuni g on d.gestiune_primitoare = g.cod_gestiune
								where d.Subunitate = @subunitate and d.Tip = 'TE' and d.Data = @data and d.Numar = @numar)

	create table #preturi(cod varchar(20))
	exec CreazaDiezPreturi

	insert into #preturi (cod)
	select pz.cod
	from #PozDocFiltr pz
	group by pz.cod

	declare 
		@px xml, @eCustodie bit
	set @eCustodie = 0

	select @tertCustodie = max(left(pz.Locatie, 13)) from #PozDocFiltr pz
	select @gestiuneCustodie = max(rtrim(pz.Gestiune_primitoare)) from #PozDocFiltr pz
	
	if (select g.detalii.value('(/row/@custodie)[1]', 'bit') from gestiuni g where g.Cod_gestiune = @gestiuneCustodie) = 1
		set @eCustodie = 1

	if isnull(@tertCustodie, '') <> '' and @eCustodie = 1
	begin
		select
			@tert = @tertCustodie,
			@gestiune = @gestiuneCustodie
	end
	else
	begin
		select
			@gestiune = (select cod_gestiune from doc where tip = 'TE' and numar = @numar and data = @data),
			@tert = (select cod_tert from doc where tip = 'TE' and numar = @numar and data = @data)
	end

	select @px = (select @gestiune as gestiune, @tert as tert, CONVERT(varchar(10), @data, 101) as data for xml raw)
	exec wIaPreturi @sesiune = @sesiune, @parXML = @px

	select 
		@delegat = isnull(rtrim(@detalii.value('(/row/@delegat)[1]', 'varchar(20)')), ''),
		@tertDelegat = isnull(rtrim(@detalii.value('(/row/@tertdelegat)[1]', 'varchar(20)')), '')
	
	/* aici se poate completa pretul de pe formular in functie de analiza, implicit este adus pretul de stoc */
	update pz 
		set pret_formular=(case when ge.tip_gestiune in ('M','P','O') then pz.pret_formular 
								when ge.tip_gestiune in ('A','V') or g.tip_gestiune in ('A','V') then pz.Pret_cu_amanuntul 
								else isnull(round(pp.pret_vanzare,2), 0) end)
	from #PozDocFiltr pz
	left join gestiuni g on pz.gestiune = g.cod_gestiune and g.Subunitate = @Subunitate
	left join gestiuni ge on pz.gestiune_primitoare =  ge.cod_gestiune and ge.Subunitate = @Subunitate	
	left join #preturi pp on pp.cod = pz.cod
	
	/** Selectul principal	**/
	select
		df.firma as firma, df.codFiscal as cif, df.ordreg as ordreg, df.judet as jud,
		df.sediu as loc, df.adresa as adr, df.cont as cont, df.banca as banca, 
		pz.numar as NUMAR, convert(varchar(10), pz.data, 103) as data, 
		rtrim(g.denumire_gestiune) as predator,
		rtrim(pz.gestiune) as cod_gestiune,
		rtrim(@detalii_gest) as primitor,
		rtrim(isnull(g.detalii.value('(/row/@adresa)[1]', 'varchar(300)'), '')) as ADRESAPRD,
		rtrim(isnull(ge.detalii.value('(/row/@adresa)[1]', 'varchar(300)'), '')) as ADRESAPRM,
		row_number() over (order by pz.numar_pozitie) as nrcrt,
		rtrim(n.Cod) as cod,
		rtrim(n.denumire) as explicatie,
		rtrim(n.um) as UM,
		round(pz.cantitate,3) as CANT,
		pz.pret_formular as PRET,
		isnull(round(pz.cantitate*pz.pret_formular,2), 0) as VALOARE,

		/** Date tert, daca se face transfer in custodie (in loc de gestiuni, pe formular vor aparea aceste date) */
		rtrim(isnull(t.Denumire, '')) as tertCustodie,
		rtrim(isnull(inf.Banca3, '')) as ordregCustodie,
		rtrim(isnull(t.cod_fiscal, '')) as cifCustodie,
		(isnull(rtrim(l.oras), rtrim(t.localitate)) + ', ' + ltrim(left(t.adresa, 20))) as sediuCustodie,
		rtrim(isnull(j.denumire, t.judet)) as judetCustodie,
		rtrim(isnull(t.cont_in_banca, '')) as contCustodie,
		(isnull(rtrim(b.Denumire), rtrim(t.banca)) + ', ' + rtrim(b.Filiala)) as bancaCustodie,
		rtrim(isnull(inf.descriere, '')) as pctLivrareCustodie,
		isnull(ge.detalii.value('(/row/@custodie)[1]', 'int'), 0) as esteCustodie,

		/** Footer - date expeditie */
		isnull(@detalii.value('(/row/@observatii)[1]', 'varchar(300)'), '') as OBSERVATII,
		isnull(rtrim(@detalii.value('(/row/@dendelegat)[1]', 'varchar(100)')), '') as NUMEDELEGAT,
		isnull(dbo.fStrToken(del.Buletin, 1, ','), '') as sr,
		isnull(dbo.fStrToken(del.Buletin, 2, ','), '') as nrbi,
		isnull(rtrim(del.Eliberat), '') as ELIB,
		isnull(rtrim(del.Mijloc_tp), '') as nrmij,
		isnull(convert(varchar(10), @detalii.value('(/row/@data_expedierii)[1]', 'datetime'), 103), convert(varchar(10), getdate(), 103)) as dataexp,
		isnull(@detalii.value('(/row/@ora_expedierii)[1]', 'varchar(6)'), '') as ORAEXP,
		'Operat: ' + rtrim(pz.utilizator) + '. Tiparit la ' + convert(varchar(10), getdate(), 103) + ' ' + convert(varchar(5), getdate(), 108)
			+ ', de catre ' + @utilizator as date_tiparire,
		pz.numar_pozitie as ordine
	into #date
	from #PozDocFiltr pz
	left join terti t on t.Subunitate = @subunitate and t.tert = left(pz.Locatie, 13)
	left join infotert inf on inf.Subunitate = @subunitate and inf.tert = t.tert and inf.Identificator <> '' and inf.Identificator = substring(pz.Locatie, 14, 5)
	left join infotert del on del.identificator = isnull(@delegat, '') and del.tert = isnull(@tertDelegat, '') and del.subunitate = 'C1'
	left join localitati l on t.localitate = l.cod_oras
	left join judete j on t.judet = j.cod_judet
	left join bancibnr b on b.Cod = t.Banca
	left join nomencl n on n.Cod = pz.Cod
	left join gestiuni g on pz.gestiune = g.cod_gestiune and g.Subunitate = @Subunitate
	left join gestiuni ge on ge.Subunitate = @Subunitate and pz.gestiune_primitoare = ge.cod_gestiune
	--left join #preturi pp on pp.cod = pz.cod
	left join #dateFirma df ON 1 = 1

	-- SP
	if exists (select 1 from sys.sysobjects where name = 'rapFormTransferuriSP')
		exec rapFormTransferuriSP @sesiune = @sesiune, @numar = @numar, @data = @data
	
	select * from #date order by ordine

end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesaj, 16, 1)
end catch
