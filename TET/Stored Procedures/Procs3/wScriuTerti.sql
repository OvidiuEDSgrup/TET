--***

create procedure wScriuTerti @sesiune varchar(50), @parXML xml
as
declare @iDoc int, @Sub char(9), @AdrComp int, @CodTertCodFisc int, @ContFImpl varchar(40), @ContBImpl varchar(40), 
	@mesaj varchar(200), @tert char(13), @cod_fiscal char(16), @alt_tert char(13), @referinta int, @tabReferinta int, @mesajEroare varchar(100), 
	@UltTert int,@locTerti int ,@JudTerti int, @eroare int,@tip_tert char(1), @detalii xml,@email varchar(2000), @dataAzi datetime, @TipTVAUnitate char(1)
	
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output 
exec luare_date_par 'GE', 'ADRCOMP', @AdrComp output, 0, ''
exec luare_date_par 'GE', 'CFISCSUGE', @CodTertCodFisc output, 0, ''
exec luare_date_par 'GE', 'CONTFURN', 0, 0, @ContFImpl output   
exec luare_date_par 'GE', 'CONTBENEF', 0, 0, @ContBImpl output   
exec luare_date_par 'GE', 'LOCTERTI', @LocTerti output, 0, ''
exec luare_date_par 'GE', 'JUDTERTI', @JudTerti output, 0, ''



begin try
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuTertiSP')
		exec wScriuTertiSP @sesiune, @parXML output

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlt') IS NOT NULL
		drop table #xmlt

	select isnull(ptupdate, 0) as ptupdate, upper(ltrim(rtrim(tert))) tert, isnull(tert_vechi, tert) as tert_vechi, ltrim(rtrim(denumire)) denumire, 
		upper(ltrim(rtrim(cod_fiscal))) cod_fiscal, isnull(cod_fiscal_vechi, '') as cod_fiscal_vechi, 
		upper(ltrim(rtrim(localitate))) localitate, judet, tara, 
		ltrim(rtrim(adresa)) adresa, ltrim(rtrim(strada)) strada, ltrim(rtrim(numar)) numar, bloc, scara, apartament, cod_postal, 
		ltrim(rtrim(telefon_fax)) telefon_fax, ltrim(rtrim(banca)) banca, upper(ltrim(rtrim(cont_in_banca))) cont_in_banca, 
		decontari_valuta, grupa, cont_furnizor, cont_beneficiar, data_tert, categ_pret, 
		sold_maxim_beneficiar, discount, termen_livrare, termen_scadenta, reprezentant, functie_reprezentant, 
		lm, responsabil, info1, info2, info3, nr_ord_reg, tip_tert, neplatitor_de_tva, nomenclator_special, isnull(email,'') email, tiptva, o_tiptva, faravalidare,
		detalii
	into #xmlt
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii/row',
		ptupdate int '@update', 
		tert varchar(13) '@tert', 
		tert_vechi varchar(13) '@o_tert', 
		denumire varchar(80) '@dentert', 
		cod_fiscal varchar(16) '@codfiscal', 
		cod_fiscal_vechi varchar(16) '@o_codfiscal', 
		localitate varchar(35) '@localitate', 
		judet varchar(20) '@judet', 
		tara varchar(20) '@tara', 
		adresa varchar(60) '@adresa', 
		strada varchar(30) '@strada', 
		numar varchar(8) '@numar', 
		bloc varchar(6) '@bloc', 
		scara varchar(5) '@scara', 
		apartament varchar(3) '@apartament', 
		cod_postal varchar(8) '@codpostal', 
		telefon_fax varchar(20) '@telefonfax', 
		banca varchar(20) '@banca', 
		cont_in_banca varchar(35) '@continbanca', 
		decontari_valuta int '@decontarivaluta', 
		grupa varchar(3) '@grupa', 
		cont_furnizor varchar(40) '@contfurn', 
		cont_beneficiar varchar(40) '@contben', 
		data_tert datetime '@datatert', 
		categ_pret int '@categpret', 
		sold_maxim_beneficiar float '@soldmaxben', 
		discount float '@discount', 
		termen_livrare int '@termenlivrare', 
		termen_scadenta int '@termenscadenta', 
		reprezentant varchar(30) '@reprezentant', 
		functie_reprezentant varchar(30) '@functiereprezentant', 
		lm varchar(9) '@lm', 
		responsabil varchar(30) '@responsabil', 
		info1 varchar(35) '@info1', 
		info2 varchar(35) '@info2', 
		info3 varchar(30) '@info3', 
		nr_ord_reg varchar(20) '@nrordreg', 
		tip_tert int '@tiptert', 
		neplatitor_de_tva int '@neplatitortva', 
		nomenclator_special int '@nomspec',
		email varchar(2000) '@email', -- mitz: am lasat 2000, pt. clientii care au nevoie(se poate mari coloana daca nu e replicare.
		tiptva varchar(1) '@tiptva',
		o_tiptva varchar(1) '@o_tiptva',
		faravalidare int '@faravalidare'
	)
	exec sp_xml_removedocument @iDoc 
	
	update #xmlt
		set decontari_valuta=1 where tip_tert in (1,2)

	-- salvarea detaliilor e tratata doar la importul unui singur tert
	select top 1 @detalii= detalii from #xmlt
	
	-- daca nu se trimite cod de tert, cod tert = cod fiscal
	update x
		set tert=left(cod_fiscal,13)
	from #xmlt x
	where @CodTertCodFisc=1 and isnull(x.tert, '')='' --and x.ptupdate=0

	set @dataAzi=convert(datetime,convert(char(10), getdate(),101), 101)

	while exists (select 1 from #xmlt x where x.ptupdate=0 and isnull(x.tert, '')='')
	begin
		if @UltTert is null
			exec luare_date_par 'GE', 'TERT', 0, @UltTert output, ''
		set @UltTert = @UltTert + 1
		while exists (select 1 from terti where subunitate=@Sub and tert=RTrim(LTrim(convert(char(9), @UltTert))))
			set @UltTert = @UltTert + 1
		update top (1) x
		set tert=RTrim(LTrim(convert(char(9), @UltTert)))
		from #xmlt x
		where x.ptupdate=0 and isnull(x.tert, '')=''
	end
	if @UltTert is not null
		exec setare_par 'GE', 'TERT', null, null, @UltTert, null

	if exists (select 1 from #xmlt where isnull(tert, '')='')
		raiserror('Cod tert necompletat', 16, 1)

	if (select MAX(ISNULL(x.faravalidare,0)) from #xmlt x)=0 
	begin
    if @JudTerti=1 
	begin
		if exists (select 1 from #xmlt where isnull(judet, '')='' and tip_tert=0) -- tip_tert=0 <=> tert intern, =1 <=> tert UE,...
			raiserror('Judet necompletat!!', 16, 1)
		else
		begin 
			if not exists (select 1 from Judete,#xmlt x where cod_judet=x.judet or x.tip_tert>0)
			begin			
				update #xmlt set judet=SUBSTRING(ltrim(rtrim(judet)),11,len(judet)-10) where ltrim(rtrim(judet)) like 'Municipiul%'--tratare caz in care se primeste 'Municipiul...'
				update #xmlt set judet=(select top 1 cod_judet from judete where replace(denumire,'-',' ') like '%'+rtrim(ltrim((convert(varchar(3),judet) COLLATE Latin1_General_CI_AI)))+'%') 
			end
			if not exists (select 1 from Judete,#xmlt x where cod_judet=x.judet or x.tip_tert>0)
				raiserror('Judet inexistent!!',16,1)
		end
    end
	if @LocTerti=1 -- lucreaza cu catalog de localitati 
	begin
		if exists (select 1 from #xmlt where isnull(localitate, '')='')
			raiserror('Localitate necompletata', 16, 1)
		else 
			begin
				if not exists (select 1 from Localitati, #xmlt x where cod_oras=x.localitate or x.tip_tert>0)
					update #xmlt set localitate=(select top 1 cod_oras from localitati where cod_judet = judet and oras like '%'+rtrim(ltrim((convert(varchar(30),localitate) COLLATE Latin1_General_CI_AI)))+'%') --from #xmlt x 
				if not exists (select 1 from Localitati, #xmlt x where cod_oras=x.localitate or x.tip_tert>0)
					raiserror('Localitate inexistenta',16,1)
			end
    end
   
    end
    
    select @tert=x.tert
	from #xmlt x, terti t 
	where t.subunitate=@Sub and t.tert=x.tert and (x.ptupdate=0 or x.ptupdate=1 and x.tert<>x.tert_vechi)
	
	if @tert is not null
	begin
		set @mesajEroare='Tertul ' + RTrim(@tert) + ' este deja introdus'
		raiserror(@mesajEroare, 16, 1)
	end
	
	select @referinta=dbo.wfRefTerti(x.tert_vechi), 
		@tert=(case when @referinta>0 and @tert is null then x.tert_vechi else @tert end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlt x
	where x.ptupdate=1 and x.tert<>x.tert_vechi
	
	if @tert is not null
	begin
		set @mesajEroare='Tertul ' + RTrim(@tert) + ' are ' + (case @tabReferinta when 1 then 'facturi' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	select @tert=x.tert, @cod_fiscal=x.cod_fiscal, @alt_tert=t.tert
	from #xmlt x, terti t 
	where t.subunitate=@Sub and x.cod_fiscal<>'' and t.cod_fiscal=x.cod_fiscal and 
			(x.ptupdate=0 or x.ptupdate=1 and x.cod_fiscal<>x.cod_fiscal_vechi and t.tert<>x.tert_vechi)

	--if @tert is not null
	--begin	
	--	set @mesajEroare='Codul fiscal ' + RTrim(@cod_fiscal) + ' al tertului ' + RTrim(@tert) + ' este deja introdus la tertul ' + RTrim(@alt_tert)
	--	raiserror(@mesajEroare, 16, 1)
	--end
	
	select @tip_tert=tip_tert from #xmlt x 
	if @tip_tert='0'
	begin
		select @tert=x.tert, @cod_fiscal=x.cod_fiscal from #xmlt x
		if  LEN(ltrim(rtrim(@cod_fiscal)))<=10 and ISNUMERIC(@cod_fiscal)=1 and exists (select 1 from #xmlt x where x.ptupdate=0) -- daca sunt in adaugare 
		begin
			exec wValidareCodFiscal @cod_fiscal , @tert, @eroare output, @mesajeroare output
			if @eroare<>0
				raiserror(@mesajEroare, 16, 1)
		end
	end

	update x
	set judet=(case when @JudTerti=1 and @locTerti=1 and x.tip_tert=0 then ISNULL((select max(cod_judet) from localitati where cod_oras=x.localitate), '') else isnull(x.judet,'') end)
	from #xmlt x
   -- where  --isnull(x.judet,'')=''
	
	update x
	set adresa=(case when @AdrComp=0 then adresa else 
		ISNULL(rtrim(strada),'') + space(30-len(rtrim(strada)))
		+ ISNULL(rtrim(numar),'') + space(8-len(rtrim(numar)))
		+ ISNULL(rtrim(left(bloc,6)),'')  + space(6-len(rtrim(bloc)))
		+ ISNULL(rtrim(left(scara,5)),'') + space(5-len(rtrim(scara)))
		+ ISNULL(rtrim(left(apartament,3)),'') +space(3-len(rtrim(apartament)))
		+ ISNULL(rtrim(left(cod_postal,8)),'') end) 
	from #xmlt x

	update x
	set cont_furnizor=(case when isnull(cont_furnizor, '')='' then @ContFImpl else cont_furnizor end), 
		cont_beneficiar=(case when isnull(cont_beneficiar, '')='' then @ContBImpl else cont_beneficiar end), 
		data_tert=(case when isnull(data_tert, '01/01/1901')<='01/01/1901' then @dataAzi else data_tert end)
	from #xmlt x
	where x.ptupdate=0
	
	declare @p xml
	select @p=(select tert, tiptva from #xmlt for xml raw)
	exec scriuTipTvaTerti @sesiune=@sesiune, @parxml=@p

	insert terti
	(Subunitate, Tert, Denumire, Cod_fiscal, Localitate, Judet, Adresa, Telefon_fax, Banca, Cont_in_banca, Tert_extern, Grupa, Cont_ca_furnizor, Cont_ca_beneficiar, Sold_ca_furnizor, Sold_ca_beneficiar, Sold_maxim_ca_beneficiar, Disccount_acordat,
	detalii)
	select @Sub, x.tert, isnull(x.denumire, ''), isnull(x.cod_fiscal, ''), isnull(x.localitate, ''), isnull((case when isnull(x.tip_tert, 0)=0 then x.judet else x.tara end), ''), 
		isnull(x.adresa, ''), isnull(x.telefon_fax, ''), isnull(x.banca, ''), isnull(x.cont_in_banca, ''), isnull(x.decontari_valuta, 0), 
		isnull(x.grupa, ''), isnull(x.cont_furnizor, ''), isnull(x.cont_beneficiar, ''), 
		693961 + datediff(d, '01/01/1901', isnull(x.data_tert, '01/01/1901')), isnull(x.categ_pret, 0), isnull(x.sold_maxim_beneficiar, 0), isnull(x.discount, 0), --> numarul 693961 reprezinta 1901-1-1 in zile
		x.detalii
	from #xmlt x
	where x.ptupdate=0

	insert infotert
	(Subunitate, Tert, Identificator, Descriere, Loc_munca, Pers_contact, Nume_delegat, Buletin, Eliberat, Mijloc_tp, Adresa2, Telefon_fax2, e_mail, Banca2, 
		Cont_in_banca2, Banca3, Cont_in_banca3, Indicator, Grupa13, Sold_ben, Discount, Zile_inc, Observatii)
	select @Sub subunitate, x.tert Tert, '' Identificator, isnull(x.responsabil, '') Descriere, isnull(x.lm, '') Loc_munca, '' Pers_contact, isnull(x.reprezentant, '') Nume_delegat, 
		'' Buletin, isnull(x.functie_reprezentant, '') Eliberat, '' Mijloc_tp, '' Adresa2, '' Telefon_fax2, x.email e_mail, '' Banca2, 
		isnull(x.info1, '') Cont_in_banca2, isnull(x.nr_ord_reg, '') Banca3, isnull(x.info2, '') Cont_in_banca3, isnull(x.nomenclator_special, 0) Indicator, 
		(case when isnull(x.neplatitor_de_tva, 0)=0 then '' else '1' end) Grupa13, isnull(x.termen_livrare, 0) Sold_ben, isnull(x.termen_scadenta, 0) Discount, 
		isnull(x.tip_tert, 0) Zile_inc, isnull(x.info3, '') Observatii
	from #xmlt x
	where x.ptupdate=0 or not exists (select 1 from infotert i where i.subunitate=@Sub and i.tert=x.tert and i.identificator='')


	update t
	set tert=isnull(x.tert, t.tert), denumire=isnull(x.denumire, t.denumire), cod_fiscal=isnull(x.cod_fiscal, t.cod_fiscal), 
		localitate=isnull(x.localitate, t.localitate), 
		judet=isnull((case when isnull(x.tip_tert, 0)=0 then x.judet else x.tara end), t.judet), 
		adresa=isnull(x.adresa, t.adresa), 
		telefon_fax=isnull(x.telefon_fax, t.telefon_fax), banca=isnull(x.banca, t.banca), cont_in_banca=isnull(x.cont_in_banca, t.cont_in_banca), 
		tert_extern=isnull(x.decontari_valuta, t.tert_extern), grupa=isnull(x.grupa, t.grupa), 
		cont_ca_furnizor=isnull(x.cont_furnizor, t.cont_ca_furnizor), cont_ca_beneficiar=isnull(x.cont_beneficiar, t.cont_ca_beneficiar), 
		sold_ca_furnizor=isnull(693961 + datediff(d, '01/01/1901', x.data_tert), t.sold_ca_furnizor), 
		sold_ca_beneficiar=isnull(x.categ_pret, t.sold_ca_beneficiar), sold_maxim_ca_beneficiar=isnull(x.sold_maxim_beneficiar, t.sold_maxim_ca_beneficiar), disccount_acordat=isnull(x.discount, t.disccount_acordat),
		t.detalii=x.detalii
	from terti t, #xmlt x
	where x.ptupdate=1 and t.subunitate=@Sub and t.tert=x.tert_vechi

	update i
	set descriere=isnull(x.responsabil, i.descriere), loc_munca=isnull(x.lm, i.loc_munca), nume_delegat=isnull(x.reprezentant, i.nume_delegat), 
		eliberat=isnull(x.functie_reprezentant, i.eliberat), cont_in_banca2=isnull(x.info1, i.cont_in_banca2), 
		banca3=isnull(x.nr_ord_reg, i.banca3), cont_in_banca3=isnull(x.info2, i.cont_in_banca3), 
		indicator=isnull(x.nomenclator_special, i.indicator), 
		grupa13=(case when x.neplatitor_de_tva is null then i.grupa13 when x.neplatitor_de_tva=1 then '1' else '0' end), 
		sold_ben=isnull(x.termen_livrare, i.sold_ben), discount=isnull(x.termen_scadenta, i.discount), 
		zile_inc=isnull(x.tip_tert, i.zile_inc), observatii=isnull(x.info3, i.observatii),
		e_mail=x.email
	from infotert i, #xmlt x
	where x.ptupdate=1 and i.subunitate=@Sub and i.tert=x.tert_vechi and i.identificator=''

	update i
		set tert=x.tert
	from infotert i, #xmlt x
	where x.ptupdate=1 and x.tert<>x.tert_vechi and (i.subunitate=@Sub or i.subunitate='C'+@Sub) and i.tert=x.tert_vechi

	-- citesc tip tva unitate
	select @TipTVAUnitate=tip_tva from TvaPeTerti where TipF='B' and Tert is null and dela<=@dataAzi
	select @TipTVAUnitate=isnull(@TipTVAUnitate,'P')
	
	-- in momentul adaugarii, inseram si tipul de tva al tertului. (modificarea acestor valori se face doar in detaliere)
	-- daca se adauga un tert si se face o factura anterioara zilei curente, poate da erori.
	insert into TvaPeTerti(tipf, tert, dela, tip_tva)
	select 'F', rtrim(x.tert), dateadd(day, -1, @dataAzi), isnull(tiptva,'N')
	from #xmlt x
	where x.ptupdate=0 and not exists (select * from TvaPeTerti t where t.Tert=x.tert and t.tipf='F')	
--	am tratat sa nu se insereze pozitii cu tip TVA='P', este tratat in procedurile de jurnal TVA si 394 ca lipsa pozitiei inseamna tip TVA=P - discutat cu Ghita.
--	am pus si null pentru cazul in care campul tip TVA nu este vizibil in macheta.
		and not (@TipTVAUnitate='P' and isnull(x.tiptva,'') in ('P',''))
--	am tratat sa nu insereze pozitii si daca tip tva unitate este Incasare 
--	in acest caz implicit toti tertii sunt asimilati ca fiind cu TVA la incasare (in macheta apar cu TVA la incasare).
		and not (@TipTVAUnitate='I' and isnull(x.tiptva,'')='I')

	if exists (select * from sysobjects where name ='ValidareDateDinVies') and exists (select 1 from #xmlt where tip_tert=1)
	begin
		IF OBJECT_ID('tempdb..#tertiVies') IS NOT NULL
			drop table #tertiVies

		create table #tertiVies (tert varchar(20))
		exec CreazaDiezTerti @numeTabela='#tertiVies'
		insert into #tertiVies (tert)
		select tert
		from #xmlt where tip_tert=1
		exec ValidareDateDinVies @sesiune=@sesiune, @parXML=@parXML
	end
	
	if @parXML.value('/row[1]/@_butonAdaugare','varchar(50)') = '1'
	begin
		set @parXML = 
			(select top 1 t.tert tert, t.denumire dentert 
			from terti t, #xmlt x 
			where x.ptupdate=0 and t.subunitate=@Sub and t.tert=x.tert
			for xml raw)
	
		if @parXML is not null
			exec wIaTerti @sesiune=@sesiune, @parXML=@parXML
	end
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (wScriuTerti)'
	raiserror(@mesaj, 11, 1)
end catch

IF OBJECT_ID('tempdb..#xmlt') IS NOT NULL
	drop table #xmlt

--select @mesaj as mesajeroare for xml raw
