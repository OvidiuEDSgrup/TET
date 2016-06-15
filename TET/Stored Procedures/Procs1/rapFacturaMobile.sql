
create procedure rapFacturaMobile (@sesiune varchar(50), @tip varchar(2), @numar varchar(20), @data datetime, @nrExemplare int=1)
as
begin try
	set transaction isolation level read uncommitted
	/*
	Formular in lei

	pret_unitar =  pret_valuta*curs (daca este)
	tva_unitar= tva_fara discount(vezi mai jos)

	pret_vanzare = pret vanzare cu discount (discountat), totdeauna in LEI

	totalfaratva =cantitate*pret_vanzare
	totaltva = sum(tva_deductibil)

	total fara discount = pret_valuta*curs(daca este)*cantitate
	tva fara discount = pret_valuta*curs(daca este)*cantitate*cota_tva

	discount aplicat se ia prin diferenta (se afiseaza doar daca exista)

	Formular in valuta - daca tert = decontari in valuta (alt formular)
	- alta forma si formule
	- valorile se impart la curs



	EXEMPLU APEL 
		exec rapFacturaMobile @sesiune='',@tip='AP', @numar='160018', @data='2014-09-03', @nrexemplare=1
	*/
	declare 
		@subunitate varchar(20), @utilizator varchar(50), @capitalSocial varchar(20), @numeFirma varchar(200), @OrdReg varchar(100), @CUI varchar(100), 
		@AdresaFirma varchar(500), @Judet varchar(100), @contBanca varchar(100), @banca varchar(100), @observatii varchar(1000)

	select top 1 
		@utilizator = RTRIM(utilizator) from pozdoc where tip=@tip and numar=@numar and data=@data

	/* Selectie date in PAR*/
	select
		@subunitate = (case when parametru = 'SUBPRO' then rtrim(val_alfanumerica) else @subunitate end),
		@numeFirma = (case when parametru = 'NUME' then rtrim(val_alfanumerica) else @numeFirma end),
		@capitalSocial = (case when parametru = 'CAPITALS' then rtrim(val_alfanumerica) else @capitalSocial end),
		@OrdReg = (case when parametru = 'ORDREG' then rtrim(val_alfanumerica) else @OrdReg end),
		@CUI = (case when parametru = 'CODFISC' then rtrim(val_alfanumerica) else @CUI end),
		@AdresaFirma = (case when parametru = 'ADRESA' then rtrim(val_alfanumerica) else @AdresaFirma end),
		@Judet = (case when parametru = 'JUDET' then rtrim(val_alfanumerica) else @Judet end),
		@contBanca = (case when parametru = 'CONTBC' then rtrim(val_alfanumerica) else @contBanca end),
		@banca = (case when parametru = 'BANCA' then rtrim(val_alfanumerica) else @banca end)
	from par
	where Tip_parametru = 'GE' 
		and Parametru in ('SUBPRO','NUME','CAPITALS','ORDREG','CODFISC','ADRESA','JUDET','CONTBC','BANCA')
	
	select top 1
		@observatii = Observatii 
	from antetBonuri a
	where Chitanta = 0 and convert(varchar(30), Numar_bon) = @numar and Data_bon = @data and isnull(Observatii, '') <> ''
	
	IF OBJECT_ID('tempdb.dbo.#PozDocFiltr') IS NOT NULL
		DROP TABLE #PozDocFiltr
	IF OBJECT_ID('tempdb.dbo.#DocFiltr') IS NOT NULL
		DROP TABLE #DocFiltr
	
	create table #DocFiltr(
		tert varchar(20), factura varchar(20), data_facturii datetime, data_scadentei datetime, total float, total_tva float, total_discount float, total_tva_nediscountat float, 
		valuta varchar(20), curs float, detalii xml, gestiune varchar(20), gestiune_primitoare varchar(20))	
	create table #PozDocFiltr (
		factura varchar(20), cod varchar(20), denumire varchar(100), um varchar(20), cantitate float, pret float, pret_valuta float, pret_vanzare float, tva_deductibil float,  
		cota_tva float, tva_unitar float, valoare float, curs float, discount_unitar float, discount float)
	

	/* Selectie date din PozDoc in #*/
	insert into #PozDocFiltr (factura, cod, denumire, um, cantitate, pret, valoare, pret_valuta, curs, cota_tva, pret_vanzare, tva_deductibil, tva_unitar, discount_unitar, discount)
	select
		max(p.factura), 
		p.cod, 
		max(n.denumire), 
		max(n.um), 
		sum(cantitate), 
		p.Pret_valuta*(case when max(p.curs)>0 then max(p.curs) else 1 end), 
		sum(round(convert(decimal(18,5),p.cantitate*p.pret_valuta*(case when p.curs>0 then p.curs else 1 end)),2)), 
		p.pret_valuta,
		max(p.curs) curs ,
		max(p.cota_tva) cota_tva,
		p.pret_vanzare,
		SUM(p.tva_deductibil),
		pret_valuta*(case when max(p.curs)>0 then max(p.curs) else 1 end)*max(p.cota_tva)/100,
		sum(round(convert(decimal(18,5),p.cantitate*p.pret_valuta*(case when p.curs>0 then p.curs else 1 end)),2)-round(convert(decimal(18,5),p.cantitate*p.pret_vanzare),2)),
		round(convert(decimal(15,2), p.discount), 2)
	from PozDoc p 
	JOIN nomencl n on p.cod=n.cod
	where p.subunitate=@subunitate and p.tip=@tip and p.numar=@numar and p.data=@data
	group by p.cod, p.pret_vanzare, p.pret_valuta, p.Discount
		
	/** Selectie date din DOC in # unde vom avea totaluri, etc **/
	insert into #DocFiltr (tert, factura, data_facturii, data_scadentei, total, total_tva, total_discount, total_tva_nediscountat, valuta, curs, detalii, gestiune, gestiune_primitoare)
	select
			d.Cod_tert,
			d.Factura factura,
			d.data_facturii,
			d.data_scadentei,						
			poz.valoare,
			poz.valoare_tva,
			poz.valoare_discount,
			poz.valoare_tva_nediscountat,			
			d.valuta,
			d.curs,
			d.detalii,
			d.Cod_gestiune,
			d.Gestiune_primitoare
	from doc d
	JOIN 
	(
		select 
			max(p.factura) factura,
			sum(round(convert(decimal(18,5),p.cantitate*p.pret_valuta*(case when p.curs>0 then p.curs else 1 end)),2)) valoare,
			sum(p.tva_deductibil) valoare_tva,
			sum(p.discount_unitar) valoare_discount,
			sum(round(p.cantitate*p.Pret_valuta*(case when p.curs>0 then p.curs else 1 end)*p.cota_tva/100.0, 2)) valoare_tva_nediscountat
		from #PozDocFiltr p		
	) poz on poz.factura=d.factura
	where d.tip=@tip and d.numar=@numar and d.data=@data
			
	if object_id('tempdb.dbo.#date_factura') is not null
		drop table #date_factura

	/* Selectul care returneaza datele din cele doua tabele */
	select 
		--> antet, totaluri, samd
		nr.N as nr,
		row_number() over (partition by nr.n order by p.cod) as nrint,
		@numeFirma as unitate,
		@capitalSocial as capital,
		@OrdReg as ordreg, 
		@CUI as codfiscal,
		@AdresaFirma as adresa,
		@Judet as judet,
		@contBanca as cont,
		@banca as banca,
		RTRIM(g.Denumire_gestiune) AS pctlucru,
		ISNULL(g.detalii.value('(/row/@adresa)[1]', 'varchar(200)'), '') AS adresa_pctlucru,
		RTRIM(d.factura) as factura,
		rtrim(t.denumire) as tert,
		rtrim(it.banca3) as ordreg_ben,
		RTRIM(t.cod_fiscal) as codfiscal_ben,
		RTRIM(isnull(j.denumire, t.judet)) as judet_ben,
		isnull(rtrim(l.oras), rtrim(t.localitate)) AS localitate_ben,
		convert(varchar(500), (isnull(rtrim(l.oras), rtrim(t.localitate)) + ', ' + ltrim(left(t.adresa, 20)))) as adresa_ben,
		rtrim(t.cont_in_banca) as cont_ben,
		(isnull(rtrim(b.Denumire), rtrim(t.banca)) + ', ' + rtrim(b.Filiala)) as banca_ben,
		rtrim(inf.Descriere) AS pctlucru_ben,
		rtrim(inf.e_mail) AS adresa_pctlucru_ben,
		d.data_facturii data,
		d.data_scadentei data_scadentei,
		datediff(day,d.data_facturii,d.data_scadentei) as zile_scadenta,

		/* Totaluri finale cu discount inclus*/
		round((case t.tert_extern when 0 then d.total - d.total_discount else (d.total - d.total_discount)/ISNULL(NULLIF(d.curs,0),1) end),2) total,
		round((case t.tert_extern when 0 then d.total - d.total_discount +d.total_tva else (d.total - d.total_discount +d.total_tva)/ISNULL(NULLIF(d.curs,0),1) end ),2) totalcutva,
		round((case t.tert_extern when 0 then d.total_tva else d.total_tva/ISNULL(NULLIF(d.curs,0),1) end),2) totaltva , 
		round((case t.tert_extern when 0 then d.total_discount else d.total_discount/ISNULL(NULLIF(d.curs,0),1) end),2) totaldiscount, 
		round((case t.tert_extern when 0 then d.total_tva_nediscountat-d.total_tva else (d.total_tva_nediscountat-d.total_tva)/ISNULL(NULLIF(d.curs,0),1) end ),2 )totaldiscounttva, 
		d.valuta,
		d.curs,
		p.cota_tva,

		--> date pozitii
		p.cod cod,
		RTRIM(p.denumire) denumire,
		RTRIM(p.um) um,
		p.cantitate cantitate,
		round((case t.tert_extern when 0 then p.pret else p.pret/ISNULL(NULLIF(d.curs,0),1) end),2) pret_unitar,
		round((case t.tert_extern when 0 then p.valoare else p.valoare/ISNULL(NULLIF(d.curs,0),1) end),2) valoare,
		round((case t.tert_extern when 0 then p.tva_unitar else p.tva_unitar/ISNULL(NULLIF(d.curs,0),1) end)*p.cantitate,2) tva_unitar,
		p.discount as discount, -- discount procentual
		round((case t.tert_extern when 0 then p.discount_unitar else p.discount_unitar/ISNULL(NULLIF(d.curs, 0), 1) end), 2) as discount_unitar,
		round((case t.tert_extern when 0 then p.pret - p.discount_unitar else (p.pret - p.discount_unitar)/ISNULL(NULLIF(d.curs,0),1) end),2) as pret_unitar_discountat,

		--> footer, delegat, samd
		isnull(convert(varchar(10), d.detalii.value('(/row/@data_expedierii)[1]', 'datetime'), 103), convert(varchar(10), getdate(), 103)) as data_expedierii,
		isnull(rtrim(del.descriere), '') as delegat,
		isnull(d.detalii.value('(/row/@ora_expedierii)[1]', 'varchar(6)'), convert(varchar(5), getdate(), 108)) as ora_expedierii,
		isnull(dbo.fStrToken(del.Buletin, 1, ','), '') as ci_delegat,
		isnull(dbo.fStrToken(del.Buletin, 2, ','), '') as cis_delegat,
		isnull(rtrim(del.Eliberat), '') as eliberat_delegat,
		isnull(rtrim(del.Mijloc_tp), '')  as auto_delegat,
		isnull((select max(rtrim(u.Nume)) from utilizatori u where u.ID = @utilizator), '') as ion,
		isnull(rtrim(dbo.wfProprietateUtilizator('CNP', @utilizator)), '') as cnp,
		convert(varchar(1000), rtrim(isnull(@observatii, d.detalii.value('(/row/@observatii)[1]', 'varchar(1000)')))) as observatii
	into #date_factura
	from #PozDocFiltr p
	JOIN #DocFiltr d on p.factura=d.factura
	JOIN Terti t on t.Subunitate = @subunitate and t.tert = d.tert
	JOIN dbo.Tally nr on nr.n <= @nrExemplare
	LEFT JOIN infotert it on it.Subunitate = @subunitate and it.Tert = t.tert and it.Identificator = ''
	LEFT JOIN infotert del on del.identificator=isnull(rtrim(d.detalii.value('(/row/@delegat)[1]', 'varchar(20)')), '')
		and del.tert=isnull(rtrim(d.detalii.value('(/row/@tertdelegat)[1]', 'varchar(20)')), '') and del.subunitate='C1'
	LEFT JOIN infotert inf ON inf.Subunitate = @subunitate AND inf.Tert = t.Tert AND inf.Identificator <> '' AND inf.Identificator = d.gestiune_primitoare
	LEFT JOIN localitati l on t.localitate = l.cod_oras
	LEFT JOIN judete j on t.judet = j.cod_judet
	LEFT JOIN bancibnr b on b.Cod = t.Banca
	LEFT JOIN gestiuni g ON g.Cod_gestiune = d.gestiune
				
	/* Se permite modificarea acestor doua tabele pentru a altera datele inainte ca ele sa fie returnate*/
	IF EXISTS (select 1 from sysobjects where name='rapFacturaMobileSP')
		exec rapFacturaMobileSP @sesiune=@sesiune, @tip= @tip, @numar = @numar, @data = @data

	if (select count(1) from #date_factura) = 0
		select 1 AS nr
	else
		select * from #date_factura

	drop table #date_factura
end try
begin catch
	declare @mesajEroare varchar(500) 
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch

