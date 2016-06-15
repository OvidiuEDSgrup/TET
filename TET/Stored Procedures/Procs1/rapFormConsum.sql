/**
	Formularul este folosit pentru a lista Consumuri si Dari in folosinta.
**/
create procedure rapFormConsum @sesiune varchar(50)=null, @tip varchar(2), @numar varchar(20), @data datetime, @nrExemplare int=1,
		--> filtre - pentru generarea de formulare pentru un set de documente; are efect doar daca @multedocumente este 1:
	@parXML xml = NULL, @numeTabelTemp varchar(100) = NULL OUTPUT,
	@multedocumente bit=0,
	@datajos datetime=null, @datasus datetime=null, @lm varchar(50)=null,
	@tert varchar(50)=null, @factura varchar(50)=null, @gestiune varchar(50)=null,
	@nrmaxim int=50000	--> @nrmaxim = numarul maxim de documente pentru a evita blocarea serverului sau rularea formularului pe prea multe date
as

declare @mesajEroare varchar(4000)
select @mesajEroare=''
begin try 
	set transaction isolation level read uncommitted
------------- setez tabela de filtrare	
	declare @dataimpl datetime
	if object_id('tempdb.dbo.#filtre') is not null drop table #filtre	

		create table #filtre (subunitate varchar(20), tip varchar(2), numar varchar(20), data datetime, utilizator varchar(50), numeutilizator varchar(50) default null, cnputilizator varchar(50) default null
			)
			
	--> determinare documente si date auxiliare in functie de filtre:
	if @multedocumente=1
	begin
		select @dataimpl=convert(varchar(20),max(case when parametru='anulimpl' then val_numerica else 0 end))+'-'+
				convert(varchar(20),max(case when parametru='lunaimpl' then val_numerica else 0 end))+'-1'
			from par p where tip_parametru='GE' and parametru in ('ANULIMPL','LUNAIMPL')

		select @datajos=isnull(@datajos,@dataimpl), @datasus=isnull(@datasus,'2900-1-1'),
				@lm=rtrim(@lm)+'%'
	end

	declare @subunitate varchar(20) 
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	
	insert into #filtre (subunitate, tip, numar, data, utilizator, numeutilizator, cnputilizator)
	select top (@nrmaxim+1) @subunitate, p.tip, numar, data, max(p.utilizator), max(rtrim(u.Nume)), isnull(rtrim(dbo.wfProprietateUtilizator('CNP', max(p.utilizator))), '')
	from pozdoc p
		left join utilizatori u on u.ID = p.utilizator
	where 
		p.tip=@tip and
		@multedocumente=0 and p.numar=@numar and p.data=@data
	group by p.tip, numar, data
	union all
	select top (@nrmaxim+1) @subunitate, p.tip, numar, data, max(p.utilizator), max(rtrim(u.Nume)), isnull(rtrim(dbo.wfProprietateUtilizator('CNP', max(p.utilizator))), '')
	from pozdoc p
		left join utilizatori u on u.ID = p.utilizator
	where 
		p.tip=@tip and
		@multedocumente=1 and
			p.data between @datajos and @datasus
			and subunitate=@subunitate
			and (@lm is null or p.loc_de_munca like @lm)
			and (@tert is null or p.tert like @tert)
			and (@factura is null or p.factura like @factura)
			and (@gestiune is null or p.gestiune like @gestiune)
	group by p.tip, numar, data
--select * from #filtre
	if (select count(1) from #filtre)>@nrmaxim
	begin
		select @mesajEroare ='Numarul de documente depaseste '+convert(varchar(20),@nrmaxim)+'! Reduceti intervalul calendaristic sau completati filtre suplimentare!'
		raiserror(@mesajEroare,16,1)
	end
---------------------- am setat tabela de filtrare
	declare
		@utilizator varchar(50)
	
	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	if object_id('tempdb..#PozDocFiltr') is not null
		drop table #PozDocFiltr

	/** Pragatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	create table [dbo].[#PozDocFiltr] ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Gestiune_primitoare] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, 
		[Cod_intrare] [varchar](13) NOT NULL, [Loc_de_munca] [varchar](9) NOT NULL, [Utilizator][varchar](20), [numar_pozitie] [int],
		[Comanda] [varchar](20), tip varchar(20), detalii_doc xml
		)

	insert into #PozDocFiltr (
		Numar, Cod, Data, Gestiune, Gestiune_primitoare, Cantitate, Pret_de_stoc, 
		Cod_intrare, Loc_de_munca, Utilizator, numar_pozitie, Comanda, tip, detalii_doc
		)
	select rtrim(pz.Numar) as Numar, rtrim(pz.Cod) as Cod, pz.Data as data, rtrim(d.Cod_gestiune) as Gestiune, 
		rtrim(d.Gestiune_primitoare) as Gestiune_primitoare, pz.Cantitate, pz.Pret_de_stoc, 
		rtrim(pz.Cod_intrare) as Cod_intrare, rtrim(d.Loc_munca), pz.Utilizator, pz.Numar_pozitie, rtrim(d.Comanda), pz.tip
		,d.detalii
	from pozdoc pz
		inner join #filtre f on pz.subunitate = f.subunitate and pz.tip = f.tip and pz.data = f.data and pz.numar = f.numar
		left join doc d on d.subunitate = pz.subunitate and d.tip = pz.tip and d.numar = pz.numar and d.data = pz.data

	create index IX1 on #pozdocfiltr(numar,cod,cod_intrare)

	/** Datele despre firma se vor stoca de acuma incolo in tabela #dateFirma */
	IF OBJECT_ID('tempdb.dbo.#dateFirma') IS NOT NULL DROP TABLE #dateFirma
	CREATE TABLE #dateFirma(locm varchar(50))
	exec wDateFirma_tabela
	insert into #dateFirma(locm)
	select distinct d.loc_de_munca from #filtre f inner join pozdoc d on f.subunitate=d.subunitate and f.numar=d.numar and f.tip=d.tip and f.data=d.data
	EXEC wDateFirma

	/** Selectul principal	**/
	select
		df.firma as UNITATE,
		rtrim(g.Cod_gestiune) as codGEST,
		rtrim(g.denumire_gestiune) as GEST,
		rtrim(p.Nume) as SALARIAT, -- pentru Dari in folosinta
		rtrim(pz.numar) as DOC,
		rtrim(lm.Cod) as codLM,
		rtrim(lm.Denumire) as LM,
		rtrim(pz.Comanda) as codCOMANDA,
		rtrim(c.Descriere) as COMANDA,
		convert(char(10), pz.data, 103) as DATA,
		row_number() over (partition by pz.numar, pz.data order by pz.numar_pozitie) as NR,
		rtrim(pz.cod_intrare) as CODI,
		rtrim(pz.cod) as COD,
		rtrim(n.denumire) as DENUMIRE,
		rtrim(n.um) as UM,
		round(pz.cantitate, 2) as CANT,
		round(pz.pret_de_stoc, 2) as PRET,
		round(pz.pret_de_stoc * pz.cantitate, 2) as VALOARE,
		isnull((select max(rtrim(u.Nume)) from utilizatori u where u.ID = pz.utilizator), '') as OPERATOR,
		/** Daca formularul este generat din Dari in folosinta, atunci persoana primitoare va fi salariatul care apare si pe macheta. **/
		(case when pz.tip = 'DF' then isnull(p.Nume, '') else isnull(detalii_doc.value('(/row/@denPersPrimitoare)[1]', 'varchar(150)'), '') end) as PRIMITOR,
		isnull(detalii_doc.value('(/row/@denPersPredatoare)[1]', 'varchar(150)'), '') as PREDATOR,
		isnull(detalii_doc.value('(/row/@denSefComp)[1]', 'varchar(150)'), '') as SEFCOMPARTIMENT,
		isnull(detalii_doc.value('(/row/@observatii)[1]', 'varchar(300)'), '') as OBSERVATII,
		'Operat: ' + rtrim (pz.utilizator) + '. Tiparit la ' + convert(varchar(10), getdate(), 103) + ' ' + convert(varchar(5), getdate(), 108)
			+ ', de catre ' + @utilizator as date_tiparire,
		pz.numar_pozitie as ordine,
		convert(varchar(50), '') as serie
	into #date
	from #PozDocFiltr pz
	left join nomencl n on n.Cod = pz.Cod
	left join gestiuni g on pz.gestiune = g.cod_gestiune and g.Subunitate = @subunitate
	left join lm on pz.Loc_de_munca = lm.Cod
	left join personal p on p.marca = pz.Gestiune_primitoare
	left join comenzi c ON c.Comanda = pz.Comanda
	left join #dateFirma df ON df.locm = pz.loc_de_munca
	
	/** Posibilitate specifice */
	if exists (select 1 from sys.sysobjects where name = 'rapFormConsum_dezvoltareSP')
		if @multedocumente=0
		exec rapFormConsum_dezvoltareSP @sesiune = @sesiune, @tip = @tip, @numar = @numar, @data = @data
		else
		exec rapFormConsum_dezvoltareSP @sesiune = @sesiune, @tip = @tip, @numar = @numar, @data = @data, @nrExemplare=@nrExemplare
			,@parXML=@parXML
			,@multedocumente=@multedocumente
			,@datajos=@datajos, @datasus=@datasus, @lm=@lm
			,@tert=@tert, @factura=@factura, @gestiune=@gestiune

	select * from #date order by data, ordine

end try
begin catch
	set @mesajEroare = ERROR_MESSAGE()+ ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if len(@mesajEroare)>0
select '' UNITATE, '' as codGEST, '' as GEST, '' as SALARIAT, '' as DOC, '' as codLM, '' as LM, '' as codCOMANDA, '' as COMANDA, '' as DATA, '' as NR, '' as CODI,
		'<EROARE>' as COD, @mesajEroare as DENUMIRE, '' as UM, '' as CANT, '' as PRET, '' as VALOARE, '' as OPERATOR, '' as PRIMITOR, '' as PREDATOR, '' as SEFCOMPARTIMENT, '' as OBSERVATII, '' as date_tiparire, '' as ordine, '' as serie
