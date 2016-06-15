--***
/* scrie puncte de livrare in infotert... functie apelata si din PVria */
create procedure wScriuPuncteLivrare @sesiune varchar(50), @parXML xml
as

declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrTert varchar(3), @AtrTert varchar(20), @AtrTertVechi varchar(20), 
	@iDoc int, @Sub char(9), @AdrPLiv int, 
	@mesaj varchar(200), @tert char(13), @punct_livrare char(5), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output 
exec luare_date_par 'GE', 'ADRPLIV', @AdrPLiv output, 0, ''

select @DouaNivele = @parXML.exist('/row/row'), 
	@RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end), 
	@PrefixAtrTert = (case when @DouaNivele=1 then '../' else '' end), 
	@AtrTert = @PrefixAtrTert + '@tert', 
	@AtrTertVechi = @PrefixAtrTert + '@o_tert'

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

IF OBJECT_ID('tempdb..#xmlpctliv') IS NOT NULL
	drop table #xmlpctliv

begin try
select identity (int, 1, 1) as numar_unic, isnull(ptupdate, 0) as ptupdate, upper(tert) as tert, isnull(tert_vechi, tert) as tert_vechi, 
		upper(punct_livrare) as punct_livrare, isnull(punct_livrare_vechi, punct_livrare) as punct_livrare_vechi, 
		descriere, upper(lm) as lm, persoana_contact, upper(localitate) as localitate, nume_delegat, upper(serie_buletin) as serie_buletin, 
		upper(numar_buletin) as numar_buletin, upper(eliberat_buletin) as eliberat_buletin, 
		mijloc_transport, adresa2, telefon_fax, judet, tara, e_mail, adresa, banca, cont_in_banca, 
		ruta, cont_client, indicator, grupa13, sold_ben, discount, zile_incasare, nr_autorizatie 
		into #xmlpctliv
	from OPENXML(@iDoc, @RowPattern)
	WITH
	(
		ptupdate int '@update', 
		tert char(13) @AtrTert, 
		tert_vechi char(13) @AtrTertVechi, 
		punct_livrare char(5) '@punctlivrare', 
		punct_livrare_vechi char(5) '@o_punctlivrare', 
		descriere char(30) '@denpunctlivrare', 
		lm char(9) '@lm', 
		persoana_contact char(20) '@persoanacontact', 
		localitate char(20) '@localitate', 
		nume_delegat char(30) '@numedelegat', 
		serie_buletin char(2) '@seriebuletin', 
		numar_buletin char(10) '@numarbuletin', 
		eliberat_buletin char(30) '@eliberatbuletin', 
		mijloc_transport char(20) '@mijloctransport', 
		adresa2 char(500) '@adresa2', 
		telefon_fax char(20) '@telefonfax', 
		judet char(20) '@judet', 
		tara char(20) '@tara', 
		e_mail varchar(2000) '@email', 
		adresa char(500) '@adresa', 
		banca char(20) '@banca', 
		cont_in_banca char(35) '@continbanca', 
		ruta char(20) '@ruta', 
		cont_client char(35) '@contclient', 
		indicator int '@indicator', 
		grupa13 char(13) '@grupa13', 
		sold_ben float '@soldben', 
		discount float '@discount', 
		zile_incasare int '@zileinc', 
		nr_autorizatie char(30) '@nrautorizatie'
	)
	exec sp_xml_removedocument @iDoc 
	
	if exists (select 1 from #xmlpctliv where isnull(tert, '')='')
		raiserror('Tert necompletat', 16, 1)
	
	update x
	set punct_livrare=(case when m.IdMax + o.numar_ordine > 99999 then '' else rtrim(ltrim(convert(char(5), m.IdMax+o.numar_ordine))) end)
	from #xmlpctliv x, 
	(
		select x.tert, max(case when isnumeric(i.identificator)=1 then convert(int, convert(float, i.identificator)) else 0 end) as IdMax
		from #xmlpctliv x
		left join infotert i on i.subunitate=@Sub and i.tert=x.tert and i.identificator<>''
		where x.ptupdate=0 and isnull(x.punct_livrare, '')=''
		group by x.tert
	) m,
	(
		select x.numar_unic, row_number() OVER (partition by tert order by numar_unic) as numar_ordine
		from #xmlpctliv x
		where x.ptupdate=0 and isnull(x.punct_livrare, '')=''
	) o
	where x.ptupdate=0 and isnull(x.punct_livrare, '')='' 
	and m.tert=x.tert and o.numar_unic=x.numar_unic
	
	if exists (select 1 from #xmlpctliv where isnull(punct_livrare, '')='')
		raiserror('Identificator punct livrare necompletat', 16, 1)
	
	select @tert=x.tert, @punct_livrare=x.punct_livrare
	from #xmlpctliv x, infotert i 
	where i.subunitate=@Sub and i.tert=x.tert and i.identificator=x.punct_livrare and (x.ptupdate=0 or x.ptupdate=1 and (x.tert<>x.tert_vechi or x.punct_livrare<>x.punct_livrare_vechi))
	if @punct_livrare is not null
	begin
		set @mesajEroare='Punctul de livrare ' + RTrim(@punct_livrare) + ' este deja introdus pentru tertul ' + RTrim(@tert)
		raiserror(@mesajEroare, 16, 1)
	end
	
	select @referinta=dbo.wfRefPuncteLivrare(x.tert_vechi, x.punct_livrare_vechi), 
		@tert=(case when @referinta>0 and @tert is null then x.tert_vechi else @tert end), 
		@punct_livrare=(case when @referinta>0 and @punct_livrare is null then x.punct_livrare_vechi else @punct_livrare end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlpctliv x
	where x.ptupdate=1 and (x.tert<>x.tert_vechi or x.punct_livrare<>x.punct_livrare_vechi)
	if @punct_livrare is not null
	begin
		set @mesajEroare='Punctul de livrare ' + RTrim(@punct_livrare) + ' al tertului ' + RTrim(@tert) + ' apare in ' + (case @tabReferinta when 1 then 'documente' else 'alte documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	update x
	set persoana_contact=x.localitate, 
		telefon_fax=(case when isnull(it.zile_inc, 0)=0 then (case when isnull(x.judet,'')='' then (select cod_judet from Localitati where cod_oras=x.localitate) else x.judet end) else x.tara end), 
		e_mail=x.adresa
	from #xmlpctliv x
	left join infotert it on it.subunitate=@Sub and it.tert=x.tert and it.identificator=''
	where @AdrPLiv=1
	
	insert infotert
	(Subunitate, Tert, Identificator, Descriere, Loc_munca, Pers_contact, 
		Nume_delegat, Buletin, Eliberat, 
		Mijloc_tp, Adresa2, Telefon_fax2, e_mail, Banca2, 
		Cont_in_banca2, Banca3, Cont_in_banca3, Indicator, 
		Grupa13, Sold_ben, Discount, Zile_inc, Observatii)
	select @Sub, x.tert, x.punct_livrare, isnull(x.descriere, ''), isnull(x.lm, ''), isnull(x.persoana_contact, ''), 
		isnull(x.nume_delegat, ''), isnull(x.serie_buletin, space(2)) + isnull(x.numar_buletin, ''), isnull(x.eliberat_buletin, ''), 
		isnull(x.mijloc_transport, ''), isnull(x.adresa2, ''), isnull(x.telefon_fax, ''), isnull(x.e_mail, ''), isnull(x.banca, ''), 
		isnull(x.cont_in_banca, ''), isnull(x.ruta, ''), isnull(x.cont_client, ''), isnull(x.indicator, 0), 
		isnull(x.grupa13, ''), isnull(x.sold_ben, 0), isnull(x.discount, 0), isnull(x.zile_incasare, 0), isnull(x.nr_autorizatie, '')
	from #xmlpctliv x
	where x.ptupdate=0
	
	update i
	set tert=isnull(x.tert, i.tert), identificator=isnull(x.punct_livrare, i.identificator), 
		descriere=isnull(x.descriere, i.descriere), loc_munca=isnull(x.lm, i.loc_munca), pers_contact=isnull(x.persoana_contact, i.pers_contact), 
		nume_delegat=isnull(x.nume_delegat, i.nume_delegat), 
		buletin=isnull(x.serie_buletin, left(i.buletin, 2)) + isnull(x.numar_buletin, substring(i.buletin, 3, 10)), 
		eliberat=isnull(x.eliberat_buletin, i.eliberat), mijloc_tp=isnull(x.mijloc_transport, i.mijloc_tp), 
		adresa2=isnull(x.adresa2, i.adresa2), telefon_fax2=isnull(x.telefon_fax, i.telefon_fax2), 
		e_mail=isnull(x.e_mail, i.e_mail), banca2=isnull(x.banca, i.banca2), 
		cont_in_banca2=isnull(x.cont_in_banca, i.cont_in_banca2), banca3=isnull(x.ruta, i.banca3), 
		cont_in_banca3=isnull(x.cont_client, i.cont_in_banca3), indicator=isnull(x.indicator, i.indicator), 
		grupa13=isnull(x.grupa13, i.grupa13), sold_ben=isnull(x.sold_ben, i.sold_ben), discount=isnull(x.discount, i.discount), 
		zile_inc=isnull(x.zile_incasare, i.zile_inc), observatii=isnull(x.nr_autorizatie, i.observatii)
	from infotert i, #xmlpctliv x
	where x.ptupdate=1 and i.subunitate=@Sub and i.tert=x.tert_vechi and i.identificator=x.punct_livrare_vechi
end try

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmlpctliv') IS NOT NULL
	drop table #xmlpctliv

--select @mesaj as mesajeroare for xml raw
