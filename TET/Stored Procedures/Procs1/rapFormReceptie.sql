/**
	Procedura de luare a datelor pentru formularul web (rdl) "Receptie PDF"

**/

create procedure rapFormReceptie @sesiune varchar(50),
	--> set de date care determina unic un document (pentru generarea formularului direct din macheta de receptii)
	@tip varchar(2),
	@numar varchar(20), @data datetime,
	--> filtre - pentru generarea de formulare pentru un set de documente; are efect doar daca @multedocumente este 0:
	@multedocumente bit=0,
	@datajos datetime=null, @datasus datetime=null, @loc_munca varchar(50)=null, @tert varchar(50)=null, @factura varchar(50)=null,
	@gestiune varchar(50)=null,
	@nrmaxim int=50000	--> @nrmaxim = numarul maxim de documente pentru a evita blocarea serverului sau rularea formularului pe prea multe date
as

declare @mesajEroare varchar(500)
select @mesajEroare=''
begin try 
set transaction isolation level read uncommitted
	if object_id('tempdb.dbo.#filtre') is not null drop table #filtre	

	declare  @dataimpl datetime
	
	declare @subunitate varchar(10)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	--> pentru simplificarea selectarii datelor voi folosi o tabela temporara pentru filtrare (si pentru culegere de date secundare):
	create table #filtre (subunitate varchar(20), tip varchar(2), numar varchar(20), data datetime, loc_munca varchar(50), codfiscallm varchar(50)
			--loc_munca varchar(50), tert varchar(50), factura varchar(50)
			)

	if @tip is null
		raiserror('Trebuie ales tipul de receptie! (RM, RS, RA, RF, RC)',16,1)
	
	if @tip in ('RA','RF','RC') -- pentru Receptii Chitante
		set @tip = 'RM'
			
	if @multedocumente=0		--> filtrare pe un document:
		insert into #filtre (subunitate, tip, numar, data, loc_munca, codfiscallm)
		select @subunitate, @tip, @numar, @data, max(p.loc_de_munca), null
		from pozdoc p where p.tip=@tip and p.numar=@numar and p.data=@data
	else
	begin					--> filtrare pe set de documente:
		select @dataimpl=convert(varchar(20),max(case when parametru='anulimpl' then val_numerica else 0 end))+'-'+
				convert(varchar(20),max(case when parametru='lunaimpl' then val_numerica else 0 end))+'-1'
			from par p where tip_parametru='GE' and parametru in ('ANULIMPL','LUNAIMPL')

		select @datajos=isnull(@datajos,@dataimpl), @datasus=isnull(@datasus,'2900-1-1'),
				@loc_munca=rtrim(@loc_munca)+'%'

		insert into #filtre (subunitate, tip, numar, data, loc_munca, codfiscallm)
		select top (@nrmaxim+1) @subunitate, p.tip, numar, data, max(p.loc_de_munca), '' --max(nullif(rtrim(pr.valoare),''))
		from pozdoc p
			--left join proprietati pr on pr.Tip = 'LM' and pr.cod=p.loc_de_munca AND pr.Cod_proprietate = 'CODFISCAL'
		where p.data between @datajos and @datasus
			and p.tip=@tip
			and subunitate=@subunitate
			and (@loc_munca is null or p.loc_de_munca like @loc_munca)
			and (@tert is null or p.tert like @tert)
			and (@factura is null or p.factura like @factura)
			and (@gestiune is null or p.gestiune like @gestiune)
		group by p.tip, numar, data
		
	end
/*	update f set codfiscallm=nullif(rtrim(pr.valoare),'')
		from #filtre f left join proprietati pr on pr.Tip = 'LM' and pr.cod=left(f.loc_munca,1) AND pr.Cod_proprietate = 'CODFISCAL'
*/
	if (select count(1) from #filtre)>@nrmaxim
	begin
		select @mesajEroare ='Numarul de documente depaseste '+convert(varchar(20),@nrmaxim)+'! Reduceti intervalul calendaristic sau completati filtre suplimentare!'
		raiserror(@mesajEroare,16,1)
	end
	declare
		@utilizator varchar(50), @detalii xml, @xmlDate xml,
		@gestiuneDetalii varchar(20), @locm varchar(50)
	
	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	if object_id('tempdb..#PozDocFiltr') is not null drop table #PozDocFiltr
	if object_id('tempdb..#contracteComenzi') is not null drop table #contracteComenzi

	/** Pregatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
	create table [dbo].[#PozDocFiltr] ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Cantfactura] [float] NOT NULL, [Pret_valuta] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL,
		[TVA_deductibil] [float] NOT NULL, [Tert] [varchar](13) NOT NULL, [Factura] [varchar](20) NOT NULL,
		[Data_facturii] [datetime] NOT NULL, numar_pozitie int, utilizator varchar(200), [Comanda] [varchar](50), [detalii] [xml],
		[Locatie] varchar(100), [Data_expirarii] datetime)

	insert into #PozDocFiltr (Numar, Cod, Data, Gestiune, Cantitate, Cantfactura, Pret_valuta, Pret_de_stoc, 
		TVA_deductibil, Tert, Factura, Data_facturii, numar_pozitie, utilizator, Comanda, detalii, Locatie, Data_expirarii)
	select 
		rtrim(pz.Numar), rtrim(pz.Cod), pz.data, rtrim(pz.Gestiune), pz.Cantitate, 
		isnull(pz.detalii.value('(/row/@cant_scriptica)[1]', 'float'),0.0) as Cantfactura,
		pz.Pret_valuta, pz.Pret_de_stoc,
		pz.TVA_deductibil, rtrim(pz.Tert), rtrim(pz.Factura), pz.Data_facturii, pz.Numar_pozitie, pz.utilizator,
		rtrim(pz.Comanda), pz.detalii, rtrim(pz.Locatie), pz.Data_expirarii
	from pozdoc pz
		inner join #filtre f on f.subunitate=pz.subunitate and f.tip=pz.tip and f.data=pz.data and f.numar=pz.numar
	where isnull(pz.subtip, '') != 'SF'
	union all
	select 
		rtrim(p2.Numar), rtrim(p2.Cod), pz.data, rtrim(p2.Gestiune), 
		p2.Cantitate*pz.pret_valuta*pz.cantitate/(select sum(p2.cantitate*p2.pret_de_stoc) from pozdoc p2 where p2.subunitate=pz.subunitate and p2.tip='RM' and p2.factura=pz.cod_intrare and p2.tert=pz.tert) as cantitate, 
		isnull(p2.detalii.value('(/row/@cant_scriptica)[1]', 'float'),0.0)*pz.pret_valuta*pz.cantitate/(select sum(p2.cantitate*p2.pret_de_stoc) from pozdoc p2 where p2.subunitate=pz.subunitate and p2.tip='RM' and p2.factura=pz.cod_intrare and p2.tert=pz.tert) as Cantfactura,
		p2.Pret_valuta, p2.Pret_de_stoc, 
		pz.TVA_deductibil*p2.Cantitate*p2.pret_de_stoc/(select sum(p2.cantitate*p2.pret_de_stoc) from pozdoc p2 where p2.subunitate=pz.subunitate and p2.tip='RM' and p2.factura=pz.cod_intrare and p2.tert=pz.tert) as TVA_deductibil, 
		rtrim(pz.Tert), rtrim(pz.Factura), pz.Data_facturii, pz.Numar_pozitie, 
		isnull((select RTRIM(LTRIM(max(nume))) from utilizatori where id=isnull(pz.utilizator,'')),rtrim(isnull(pz.utilizator,''))),
		isnull(p2.lot,p2.cod_intrare), p2.detalii, rtrim(p2.Locatie), p2.Data_expirarii
	from pozdoc pz
		inner join #filtre f on f.subunitate=pz.subunitate and f.tip=pz.tip and f.data=pz.data and f.numar=pz.numar
		inner join pozdoc p2 on p2.subunitate=pz.subunitate and p2.tip='RM' and p2.factura=pz.cod_intrare and p2.tert=pz.tert
	where isnull(pz.subtip, '') = 'SF'

	create index IX1 on #pozdocfiltr(factura,data_facturii)
	create index IX2 on #pozdocfiltr(cod)
	create index IX3 on #pozdocfiltr(cantitate, pret_valuta)

	select top 1 @detalii = detalii, @locm = RTRIM(Loc_munca) from doc where tip = @tip and numar = @numar and data = @data

	/** Datele despre firma se vor stoca de acuma incolo in tabela #dateFirma */
	IF OBJECT_ID('tempdb.dbo.#dateFirma') IS NOT NULL DROP TABLE #dateFirma
	
	CREATE TABLE #dateFirma(locm varchar(50))
	exec wDateFirma_tabela
	insert into #dateFirma(locm)
	select distinct isnull(d.loc_de_munca,'') from #filtre f inner join pozdoc d on f.subunitate=d.subunitate and f.numar=d.numar and f.tip=d.tip and f.data=d.data
	
	EXEC wDateFirma @locm=@loc_munca
	
	/** Pentru documentele nou create, daca nu se seteaza datele de formular prin operatie, se vor lua datele gestiunii: */
	declare cr cursor for
	select f.subunitate, f.tip, f.numar, f.data from #filtre f inner join doc d on f.subunitate=d.subunitate and f.tip=d.tip and f.numar=d.numar and f.data=d.data
		where (d.detalii is null or @detalii.exist('(/row/@gestionar)[1]') = 0)

	open cr
	fetch next from cr into @subunitate, @tip, @numar, @data
	while (@@fetch_status=0)
	begin
		select top 1 @gestiuneDetalii = rtrim(Cod_gestiune) from doc where tip = @tip and numar = @numar and data = @data
		select top 1 @detalii = detalii from gestiuni where cod_gestiune = @gestiuneDetalii
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
		fetch next from cr into @subunitate, @tip, @numar, @data
	end
	close cr
	deallocate cr

	/** Pentru receptiile generate din Contracte/Comenzi, vom face o lista cu numerele. 
		Pe o receptie pot exista pozitii care au legaturi in doua sau mai multe Contracte/Comenzi. */
	declare @lista_comenzi varchar(200)
	set @lista_comenzi = ''

	select rtrim(c.numar) as numar into #contracteComenzi
	from pozdoc p
		inner join #filtre f on f.subunitate=p.subunitate and f.tip=p.tip and f.data=p.data and f.numar=p.numar
		inner join legaturiContracte lc on lc.idPozDoc = p.idPozDoc
		inner join pozContracte pc ON pc.idPozContract = lc.idPozContract
		inner join Contracte c ON c.idContract = pc.idContract
	order by c.numar

	select @lista_comenzi = @lista_comenzi + cc.numar + ', ' from #contracteComenzi cc

	if len(@lista_comenzi) > 1
		select @lista_comenzi = left(@lista_comenzi, len(@lista_comenzi) - 1)

	/** Selectul principal	**/
	select
		d.firma as UNITATE, f.codFiscallm as CUI, d.ordreg as ORDREG, d.cont as CONT, d.banca as BANCA, 
		convert(varchar(10), pz.data, 103) as DATA, ltrim(pz.numar) as DOC,
		--'' as DATA, '' doc,
		rtrim(pz.cod) as COD,
		ltrim(rtrim(g.denumire_gestiune)) as GEST,
		isnull(rtrim(ltrim(t.denumire)), '') as FURN,
		rtrim(ltrim(pz.factura)) as FACT,
		convert(varchar(10), pz.data_facturii, 103) as DATA_FACTURII,
		@lista_comenzi as comanda,
		rtrim(n.denumire) as DENUMIRE,
		RTRIM(n.um) as UM,
		pz.pret_de_stoc as PRET,
		round(pz.cantitate, 3) as CANT,
		round(convert(decimal(18,5),pz.cantitate*pz.pret_de_stoc),2) as VAL,
		round(pz.TVA_deductibil, 2) as TVA,
		round(isnull(dvi.tva_dvi, 0) + isnull(rp.tva_rp, 0), 2) as tva_dvi_rp,
		rtrim(pz.Locatie) as locatie,
		convert(varchar(10), pz.Data_expirarii, 103) AS data_expirarii,

		/** Campuri pentru Receptie diferente */
		datepart(dd, pz.data) as ziua,
		datepart(mm, pz.data) as luna,
		datepart(yyyy, pz.data) as anul,
		convert(varchar(10), pz.data, 104) as dataReceptieDif,
		convert(varchar(10), pz.data_facturii, 104) as dataFacturiiDif,
		-- daca nu se completeaza cantitatea din documente sa se puna cantitatea pozitiei
		isnull(convert(decimal(15,3), pz.detalii.value('(/row/@cant_scriptica)[1]', 'float')), pz.Cantitate) as cant_scriptica,
		abs(convert(decimal(15,3), pz.cantitate - isnull(pz.detalii.value('(/row/@cant_scriptica)[1]', 'float'), pz.cantitate))) as diferenta,

		/** doc.detalii */
		isnull(nullif(doc.detalii.value('(/row/@denmembru1)[1]', 'varchar(150)'),''), g.detalii.value('(/row/@membru1)[1]','varchar(150)')) as MEMBR1,
		isnull(nullif(doc.detalii.value('(/row/@denmembru2)[1]', 'varchar(150)'),''), g.detalii.value('(/row/@membru2)[1]','varchar(150)')) as MEMBR2,
		isnull(nullif(doc.detalii.value('(/row/@denmembru3)[1]', 'varchar(150)'),''), g.detalii.value('(/row/@membru3)[1]','varchar(150)')) as MEMBR3,
		isnull(nullif(doc.detalii.value('(/row/@denmembru4)[1]', 'varchar(150)'),''), g.detalii.value('(/row/@membru4)[1]','varchar(150)')) as MEMBR4,
		isnull(doc.detalii.value('(/row/@observatii)[1]', 'varchar(300)'), '') as OBSERVATII,
		isnull(nullif(doc.detalii.value('(/row/@gestionar)[1]', 'varchar(50)'),''), g.detalii.value('(/row/@gestionar)[1]','varchar(150)')) AS gestionar,
		isnull(nullif(doc.detalii.value('(/row/@dengestionar)[1]', 'varchar(150)'),''), g.detalii.value('(/row/@dengestionar)[1]','varchar(150)')) AS dengestionar,
		'Operat: ' + rtrim (pz.utilizator) + '. Tiparit la ' + convert(varchar(10), getdate(), 103) + ' ' + convert(varchar(5), getdate(), 108) + ', de catre ' + @utilizator as date_tiparire,
		pz.numar_pozitie as ordine
	into #date
	from #PozDocFiltr pz
		left join doc on @subunitate=doc.subunitate and @tip=doc.tip and pz.data=doc.data and pz.numar=doc.numar
		left join terti t on t.Tert = pz.Tert and t.Subunitate = @Subunitate
		left join nomencl n on n.Cod = pz.Cod
		left join gestiuni g on pz.gestiune = g.cod_gestiune and g.subunitate = @subunitate
		left join #dateFirma d ON d.locm = doc.loc_munca
			--> mai fac o data join-ul ca sa iau codul fiscal in functie de locul de munca:
		left join #filtre f on f.subunitate=@subunitate and f.tip=@tip and f.data=pz.data and f.numar=pz.numar
		outer apply (select sum(DVI.tva_22) as tva_dvi from DVI where DVI.Subunitate = @subunitate and DVI.Numar_receptie = pz.numar and DVI.Data_receptiei = pz.data) as dvi
						--inner join #filtre f on DVI.subunitate=f.subunitate /*and DVI.tip=f.tip*/ and DVI.Numar_receptie=f.numar and DVI.Data_receptiei=f.data) as dvi
		outer apply (select sum(p.TVA_deductibil) as tva_rp from pozdoc p where p.Subunitate = @subunitate and p.Tip = 'RP' and p.Numar = pz.numar and p.Data = pz.data
						--inner join #filtre f on p.subunitate=f.subunitate and p.tip='RP' and p.numar=f.numar and p.data=f.data
		) as rp
	
	--SP
	if exists (select 1 from sys.sysobjects where name = 'rapFormReceptieSP')
		exec rapFormReceptieSP @sesiune = @sesiune, @tip = @tip, @numar = @numar, @data = @data
	
	select row_number() over (partition by furn, doc, data
		order by furn, doc, ordine) as NR,
		* from #date order by furn, doc, ordine

end try
begin catch
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

begin try	--> poate trebuie inchis cursorul...
	close cr
	deallocate cr
end try
begin catch
end catch

-->!!!!!!!!!! de facut metoda de returnare a erorii:
	--> select '<EROARE>',... [from #date]
if len(@mesajEroare)>0
select	'' NR, '' UNITATE, '' CUI, '' ORDREG, '' CONT, '' BANCA, '' DATA, '' DOC, '' COD, '' GEST, '' FURN, '' FACT, '' DATA_FACTURII,
		'' comanda, '' DENUMIRE, '' UM, '' PRET, '' CANT, '' VAL, '' TVA, '' tva_dvi_rp, '' ziua, '' luna, '' anul, '' dataReceptieDif,
		'' dataFacturiiDif, '' cant_scriptica, '' diferenta, '' MEMBR1, '' MEMBR2, '' MEMBR3, '' MEMBR4, '' OBSERVATII, '<EROARE>' gestionar,
		@mesajEroare dengestionar, '' date_tiparire, '' ordine

if object_id('tempdb.dbo.#contracteComenzi') is not null drop table #contracteComenzi
if object_id('tempdb.dbo.#filtre') is not null drop table #filtre
if object_id('tempdb..#PozDocFiltr') is not null drop table #PozDocFiltr
