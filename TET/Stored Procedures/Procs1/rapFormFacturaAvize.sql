/**	
	Procedura de luare date de tip detaliu pentru formularul web (rdl) "Formular factura"
*/
create procedure rapFormFacturaAvize (@sesiune varchar(50), @tip varchar(2), @numar varchar(20), @data datetime, @antet int = 0,
	@parXML xml = '<row/>', @nrExemplare int = 2)
as
if exists (select 1 from sys.sysobjects where name = 'rapFormFacturaAvizeSP' and type = 'P')
begin
	exec rapFormFacturaAvizeSP @sesiune = @sesiune, @tip = @tip, @numar = @numar, @data = @data, @antet = @antet, @parXML = @parXML
	return
end

declare @eroare varchar(2000)
set @eroare = ''
begin try
	set transaction isolation level read uncommitted
	declare 
		@subunitate varchar(20), @detalii xml, @delegat varchar(20), @tertDelegat varchar(20),
		@utilizatorASiS varchar(50), @capitalSocial varchar(20), @numeFirma varchar(200), @OrdReg varchar(100), @CUI varchar(100), 
		@AdresaFirma varchar(500), @Judet varchar(100), @contBanca varchar(100), @banca varchar(100), @numar_aviz varchar(300)


	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizatorASiS output

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

	IF OBJECT_ID('tempdb..#avize') IS NOT NULL
			drop table #avize
	create table #avize (factura varchar(20))

	IF OBJECT_ID('tempdb..#pozFactura') IS NOT NULL
			drop table #pozFactura
		
	select * into #pozFactura from PozDoC where Subunitate=@subunitate and tip=@tip and numar=@numar and data=@data

	IF EXISTS (select 1 from #pozFactura where subtip<>'IF' or cont_venituri<>'418')
		raiserror('Factura selectata nu este o factura pentru avize',16,1)

	insert into #avize(factura)
	select distinct cod_intrare from #pozFactura

	select @numar_aviz=''
	select @numar_aviz=@numar_aviz+rtrim(factura)+',' from #avize
	select @numar_aviz=LEFT(@numar_aviz, len(@numar_aviz)-1)
	-- pentru cazurile in care numar AP <> numar factura(facturi generate din alte app, cum ar fi softul de la Arobs)
	if @tip = 'AP' and not exists (select 1 from pozdoc where Subunitate = @subunitate and tip = @tip and Numar = @numar and Data = @data)
		select @numar = max(numar) from pozdoc where Subunitate = @subunitate and tip = @tip and Factura = @numar and Data = @data
	
	if @antet = 0 --> selectie set date pentru pozitii
	begin
		select 
			rtrim((case when max(n.tip) != 'F' then max(n.denumire) 
				else (select max(denumire) from mfix where subunitate <> 'DENS' and numar_de_inventar = max(p.cod_intrare))
			end)) as denumire,
			(case when max(p.barcod) = '' then max(n.um) else max(n.um_1) end) as um,
			sum(p.cantitate) as cantitate,
			max(p.pret_vanzare) as pret_unitar,
			sum(p.cantitate * p.pret_vanzare) as valoare,
			sum(isnull(p.tva_deductibil, 0)) as tva,
			max(p.pret_valuta) as pret_valuta, nr.n as nr,
			row_number() over (partition by nr.n order by p.cod) as nrcint
		from pozdoc p
		JOIN #avize a on p.tip='AP' and p.numar=a.factura
		inner join dbo.Tally nr on nr.n <= @nrExemplare
		inner join nomencl n on p.cod = n.cod
		where p.subunitate = @subunitate
		group by p.cod, p.pret_vanzare, p.pret_valuta, nr.n
		order by p.cod, p.pret_vanzare, p.pret_valuta
		return
	end
	
	--> selectie set date pentru antet/footer
	declare @factura varchar(50), @tert varchar(50), @identificator varchar(50), @totalTva decimal(20,2), @tva varchar(20),
		@totalCuTva decimal(20,2), @totalFaraTva decimal(20,2)
	
	select
		@factura = max(p.Factura), @tert = max(p.Tert), @identificator = max(substring(p.numar_DVI,14,5)),
		@totalTva = sum(isnull(p.tva_deductibil, 0)), @tva = max(isnull(p.Cota_TVA, 0)),
		@totalFaraTva = sum(isnull(p.Pret_vanzare, 0)), 
		@totalCuTva = @totalfaraTva + @totalTva
	from pozdoc p 
	JOIN #avize a on p.tip='AP' and p.numar=a.factura
	where p.subunitate = @subunitate
	
	/** Luam detaliile din doc, de unde vom citi datele specifice (ex. la Avize, se vor citi datele de expeditie - nu din anexafac!) */
	select top 1 @detalii = detalii from doc where tip = @tip and numar = @numar and data = @data
	select 
		@delegat = isnull(rtrim(@detalii.value('(/row/@delegat)[1]', 'varchar(20)')), ''),
		@tertDelegat = isnull(rtrim(@detalii.value('(/row/@tertdelegat)[1]', 'varchar(20)')), '')

	select top 1
	--> header
		@numeFirma as UNITATE,
		@capitalSocial as CAPITALS,
		isnull(rtrim(it.Banca3), '') as ORDREG, 
		@CUI as CUI,
		@AdresaFirma as ADR,
		@Judet as JUD,
		@contBanca as CT,
		@banca as BC,
		@tva as TVA,	--?
		rtrim(@factura) as FACTURA,
		(select max(descriere) from infotert where subunitate = @subunitate and tert = @tert and identificator = @identificator) as PCTL,
		rtrim(t.denumire) as TERT,
		rtrim((select max(banca3) from infotert where subunitate = @subunitate and tert = @tert and identificator = '')) as ORCC,
		RTRIM(t.cod_fiscal) as CODFISC,
		RTRIM(t.adresa) as ADRESA,
		RTRIM(t.judet) as JUDET,
		rtrim(t.cont_in_banca) as CONT,
		rtrim(t.banca) as BANCA,
		(select max(p.Data_scadentei) from pozdoc p where p.Subunitate = @subunitate and p.Tip = @tip 
			and p.Numar = @numar and p.Data = @data) as SCADENTA,
		@numar_aviz numar_aviz,
	--> footer
		isnull(convert(varchar(10), @detalii.value('(/row/@data_expedierii)[1]', 'datetime'), 103), convert(varchar(10), getdate(), 103)) as DAT,
		isnull(rtrim(@detalii.value('(/row/@dendelegat)[1]', 'varchar(100)')), '') as DELEG,
		isnull(@detalii.value('(/row/@ora_expedierii)[1]', 'varchar(6)'), '') as ORA,
		(select isnull(max(dbo.fStrToken(Buletin, 1, ',')), '') from infotert where Subunitate = 'C1' and Tert = @tertDelegat 
			and Identificator = @delegat) as CI,
		(select isnull(max(dbo.fStrToken(Buletin, 2, ',')), '') from infotert where Subunitate = 'C1' and Tert = @tertDelegat
			and Identificator = @delegat) as CIS,
		(select isnull(rtrim(max(Eliberat)), '') from infotert where Subunitate = 'C1' and Tert = @tertDelegat
			and Identificator = @delegat) as POLITIA,
		(select isnull(rtrim(max(Mijloc_tp)), '') from infotert where Subunitate = 'C1' and Tert = @tertDelegat
			and Identificator = @delegat) as AUTO,
		isnull((select max(rtrim(u.Nume)) from utilizatori u where u.ID = @utilizatorASiS), '') as ION,
		isnull(dbo.wfProprietateUtilizator('CNP', @utilizatorASiS), '') as CNP,
		@totalTva as tvatotal, @totalFaraTva as totalfaratva, @totalCuTva as totalcutva,
		'' as SERIA,
		isnull(@detalii.value('(/row/@observatii)[1]', 'varchar(300)'), '') as OBSERVATII
	from terti t 
	left outer join infotert it on it.Subunitate = @subunitate and it.Tert = @tert and it.Identificator = ''
	--left outer join anexafac a on a.Numar_factura = @factura and a.subunitate = @subunitate
	where t.Tert = @tert 
		and t.subunitate = @subunitate 
		
	if @@rowcount = 0
	begin
		if not exists (select 1 from pozdoc where Subunitate = '1' and tip = @tip and Numar = @numar and Data = @data)
			raiserror('Factura nu exista in baza de date!', 16, 1)
		if not exists (select 1 from terti t where t.Tert = @tert and t.Subunitate = @subunitate) 
			raiserror('Tertul facturii nu exista in baza de date!', 16, 1)
		--if not exists (select 1 from anexafac a where  a.Numar_factura=@factura and a.Subunitate=@subunitate) 
		--	raiserror ('Datele expeditiei pentru factura nu exista in baza de date!',16,1)
	end

end try
begin catch
	set @eroare = ERROR_MESSAGE() + ' (rapFormFacturaAvize)'
end catch

if (len(@eroare) > 0)
	raiserror(@eroare, 16, 1)
