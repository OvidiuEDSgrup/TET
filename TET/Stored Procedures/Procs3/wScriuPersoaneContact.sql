--***
/* scrie persoane de contat... functie apelata si din PVria */
create procedure wScriuPersoaneContact @sesiune varchar(50), @parXML xml
as

declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrTert varchar(3), @AtrTert varchar(200), @AtrTertVechi varchar(20), 
	@iDoc int, @Sub char(9), @tip varchar(2),
	@mesaj varchar(200), @tert char(13), @identificator char(5), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output 

select @tip = isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 

select @DouaNivele = @parXML.exist('/row/row'), 
	@RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end), 
	@PrefixAtrTert = (case when @DouaNivele=1 then '../' else '' end), 
	@AtrTert = @PrefixAtrTert + '@tert', 
	@AtrTertVechi = @PrefixAtrTert + '@o_tert'

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

IF OBJECT_ID('tempdb..#xmlpersct') IS NOT NULL
	drop table #xmlpersct

begin try
	select identity (int, 1, 1) as numar_unic, isnull(ptupdate, 0) as ptupdate, upper(tert) as tert, isnull(tert_vechi, tert) as tert_vechi, 
		identificator, isnull(identificator_vechi, identificator) as identificator_vechi, 
		upper(lm) as lm, persoana_contact, nume_delegat, upper(serie_buletin) as serie_buletin, upper(numar_buletin) as numar_buletin, upper(eliberat_buletin) as eliberat_buletin, 
		upper(mijloc_transport) as mijloc_transport, judet, localitate, telefon_fax, e_mail, banca2, cont_in_banca2, 
		numar, bloc, scara, apartament, cont_in_banca3, indicator, grupa13, data_nasterii, discount, zile_incasare, observatii 
		into #xmlpersct
	from OPENXML(@iDoc, @RowPattern)
	WITH
	(
		ptupdate int '@update', 
		tert char(13) @AtrTert, 
		tert_vechi char(13) @AtrTertVechi, 
		identificator char(5) '@identificator', 
		identificator_vechi char(5) '@o_identificator', 
		lm char(9) '@info3', 
		persoana_contact char(20) '@nume', 
		nume_delegat char(30) '@prenume', 
		serie_buletin char(12) '@seriebuletin', 
		numar_buletin char(12) '@numarbuletin', 
		eliberat_buletin char(30) '@eliberatbuletin', 
		mijloc_transport char(20) '@functie', 
		judet char(20) '@judet', 
		localitate char(20) '@localitate', 
		telefon_fax char(20) '@telefon', 
		e_mail varchar(2000) '@email', 
		banca2 char(20) '@strada', 
		cont_in_banca2 char(35) '@info1', 
		numar char(20) '@numar', 
		bloc char(20) '@bloc', 
		scara char(20) '@scara', 
		apartament char(20) '@apartament', 
		cont_in_banca3 char(35) '@info2', 
		indicator int '@info4', 
		grupa13 char(13) '@codpostal', 
		data_nasterii datetime '@datanasterii', 
		discount float '@info6', 
		zile_incasare int '@info5', 
		observatii char(30) '@info7'
	)
	exec sp_xml_removedocument @iDoc 

	if @parXML.exist('/row/@_butonAdaugare')=1 and @parXML.value('(/row/detalii/row/@tertdelegat)[1]','varchar(20)') is not null			-- Daca se adauga un tert din form de tip ACA, se citeste tertul delegat din detalii
		update x
		set tert=@parXML.value('(/row/detalii/row/@tertdelegat)[1]','varchar(20)')
		from #xmlpersct x
	
	if exists (select 1 from #xmlpersct where isnull(tert, '')='')
		raiserror('Tert necompletat', 16, 1)
	
	update x
	set identificator=(case when m.IdMax + o.numar_ordine > 99999 then '' else rtrim(ltrim(convert(char(5), m.IdMax+o.numar_ordine))) end)
	from #xmlpersct x, 
	(
		select x.tert, max(case when isnumeric(i.identificator)=1 then convert(int, convert(float, i.identificator)) else 0 end) as IdMax
		from #xmlpersct x
		left join infotert i on i.subunitate='C'+@Sub and i.tert=x.tert and i.identificator<>''
		where x.ptupdate=0 and isnull(x.identificator, '')=''
		group by x.tert
	) m,
	(
		select x.numar_unic, row_number() OVER (partition by tert order by numar_unic) as numar_ordine
		from #xmlpersct x
		where x.ptupdate=0 and isnull(x.identificator, '')=''
	) o
	where x.ptupdate=0 and isnull(x.identificator, '')='' 
	and m.tert=x.tert and o.numar_unic=x.numar_unic
	
	if exists (select 1 from #xmlpersct where isnull(identificator, '')='')
		raiserror('Identificator persoana de contact necompletat', 16, 1)
	
	select @tert=x.tert, @identificator=x.identificator
	from #xmlpersct x, infotert i 
	where i.subunitate='C'+@Sub and i.tert=x.tert and i.identificator=x.identificator and (x.ptupdate=0 or x.ptupdate=1 and (x.tert<>x.tert_vechi or x.identificator<>x.identificator_vechi))
	if @identificator is not null
	begin
		set @mesajEroare='Persoana de contact ' + RTrim(@identificator) + ' este deja introdusa pentru tertul ' + RTrim(@tert)
		raiserror(@mesajEroare, 16, 1)
	end
	
	select @referinta=dbo.wfRefPersoaneContact(x.tert_vechi, x.identificator_vechi), 
		@tert=(case when @referinta>0 and @tert is null then x.tert_vechi else @tert end), 
		@identificator=(case when @referinta>0 and @identificator is null then x.identificator_vechi else @identificator end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlpersct x
	where x.ptupdate=1 and (x.tert<>x.tert_vechi or x.identificator<>x.identificator_vechi)
	if @identificator is not null
	begin
		set @mesajEroare='Persoana de contact ' + RTrim(@identificator) + ' a tertului ' + RTrim(@tert) + ' apare in ' + (case @tabReferinta when 1 then 'documente' else 'alte documente' end)
		raiserror(@mesajEroare, 16, 1)
	end

	insert infotert
	(Subunitate, Tert, Identificator, 
		Descriere, 
		Loc_munca, Pers_contact, Nume_delegat, 
		Buletin, Eliberat, 
		Mijloc_tp, Adresa2, 
		Telefon_fax2, e_mail, Banca2, 
		Cont_in_banca2, Banca3, Cont_in_banca3, Indicator, 
		Grupa13, Sold_ben, Discount, Zile_inc, Observatii)
	select 'C'+@Sub, x.tert, x.identificator, left(rtrim(isnull(x.persoana_contact, '')) + ' ' + rtrim(isnull(x.nume_delegat, '')), 30), 
		isnull(x.lm, ''), isnull(x.persoana_contact, ''), isnull(x.nume_delegat, ''), 
		rtrim(isnull(x.serie_buletin, '')) + ',' + rtrim(isnull(x.numar_buletin, '')), isnull(x.eliberat_buletin, ''), 
		isnull(x.mijloc_transport, ''), rtrim(isnull(x.judet, '')) + ',' + rtrim(isnull(x.localitate, '')), 
		isnull(x.telefon_fax, ''), isnull(x.e_mail, ''), isnull(x.banca2, ''), isnull(x.cont_in_banca2, ''), 
		rtrim(isnull(x.numar, '')) + ',' + rtrim(isnull(x.bloc, '')) + ',' + rtrim(isnull(x.scara, '')) + ',' + rtrim(isnull(x.apartament, '')), 
		isnull(x.cont_in_banca3, ''), isnull(x.indicator, 0), isnull(x.grupa13, ''), 
		693961 + datediff(d, '01/01/1901', isnull(x.data_nasterii, '01/01/1901')), 
		isnull(x.discount, 0), isnull(x.zile_incasare, 0), isnull(x.observatii, '')
	from #xmlpersct x
	where x.ptupdate=0
	
	update i
	set tert=isnull(x.tert, i.tert), identificator=isnull(x.identificator, i.identificator), 
		descriere=left(rtrim(isnull(x.persoana_contact, i.pers_contact)) + ' ' + rtrim(isnull(x.nume_delegat, i.nume_delegat)), 30), 
		loc_munca=isnull(x.lm, i.loc_munca), pers_contact=isnull(x.persoana_contact, i.pers_contact), 
		nume_delegat=isnull(x.nume_delegat, i.nume_delegat), 
		buletin=rtrim(isnull(x.serie_buletin, dbo.fStrToken(i.buletin, 1, ','))) + ',' + rtrim(isnull(x.numar_buletin, dbo.fStrToken(i.buletin, 2, ','))), 
		eliberat=isnull(x.eliberat_buletin, i.eliberat), mijloc_tp=isnull(x.mijloc_transport, i.mijloc_tp), 
		adresa2=rtrim(isnull(x.judet, dbo.fStrToken(i.adresa2, 1, ','))) + ',' + rtrim(isnull(x.localitate, dbo.fStrToken(i.adresa2, 2, ','))), 
		telefon_fax2=isnull(x.telefon_fax, i.telefon_fax2), 
		e_mail=isnull(x.e_mail, i.e_mail), banca2=isnull(x.banca2, i.banca2), 
		cont_in_banca2=isnull(x.cont_in_banca2, i.cont_in_banca2), 
		banca3=rtrim(isnull(x.numar, dbo.fStrToken(i.banca3, 1, ','))) + ',' + rtrim(isnull(x.bloc, dbo.fStrToken(i.banca3, 2, ','))) + ',' + rtrim(isnull(x.scara, dbo.fStrToken(i.banca3, 3, ','))) + ',' + rtrim(isnull(x.apartament, dbo.fStrToken(i.banca3, 4, ','))), 
		cont_in_banca3=isnull(x.cont_in_banca3, i.cont_in_banca3), indicator=isnull(x.indicator, i.indicator), 
		grupa13=isnull(x.grupa13, i.grupa13), 
		sold_ben=isnull(693961 + datediff(d, '01/01/1901', x.data_nasterii), i.sold_ben), 
		discount=isnull(x.discount, i.discount), 
		zile_inc=isnull(x.zile_incasare, i.zile_inc), observatii=isnull(x.observatii, i.observatii)
	from infotert i, #xmlpersct x
	where x.ptupdate=1 and i.subunitate='C'+@Sub and i.tert=x.tert_vechi and i.identificator=x.identificator_vechi
	
	--refresh pozitii in cazul in care tipul este 'SA'-> tab de tip pozdoc
	if @tip in ('SA','EV')
	begin
		declare @docXMLIaPersoaneContact xml
		set @tert= (select top 1 x.tert from #xmlpersct x)
		set @docXMLIaPersoaneContact='<row tert="'+rtrim(@tert)+ '" tip="'+@tip +'"/>'
		exec wIaPersoaneContact @sesiune=@sesiune, @parXML=@docXMLIaPersoaneContact
	end

	if @parXML.value('/row[1]/@_butonAdaugare','varchar(50)') = '1'
	begin
		select top 1 rtrim(i.Identificator) as detalii_delegat, rtrim(i.descriere) detalii_dendelegat
			from #xmlpersct x
				inner join infotert i on x.tert=i.Tert and x.persoana_contact=i.Pers_contact and x.nume_delegat=i.nume_delegat
		where x.ptupdate=0
		for xml raw, root('Date')
	end
end try

begin catch
	set @mesaj = ERROR_MESSAGE()+ ' (wScriuPersoaneContact)'
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmlpersct') IS NOT NULL
	drop table #xmlpersct
