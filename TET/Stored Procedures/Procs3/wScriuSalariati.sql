--***
Create procedure wScriuSalariati @sesiune varchar(50), @parXML xml
as 

Declare @tip varchar(20), @codMeniu varchar(50), @iDoc int, @ptupdate int, @o_marca varchar(6), @marca varchar(6), @nume varchar(50), @functie char(30), @lm char(9),
@cnp varchar(13), @datanasterii datetime, @sex int, @reglucr decimal(5,2), @oreluna decimal(3), @pCassInd decimal(5,2), @pCasaSan varchar(20), @pasaport varchar(50), 
@UltMarca varchar(6), @Luna_inch int, @Anul_inch int, @RegimLV int, @Somesana int, @Data datetime, @detalii xml, 
@referinta int, @tabReferinta int, @eroare int, @mesaj varchar(254), @mesajEroare varchar(254), @varmesaj varchar(254), @MarcaPeCNP varchar(6), @NumePeCNP varchar(100)

set @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(20)'),'')
set @codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(50)'),'')
set @ptupdate=isnull(@parXML.value('(/row/@update)[1]','int'),0)
set @pCasaSan=dbo.iauParA('PS','CODJUDETA')
set @Luna_inch=dbo.iauParN('PS','LUNA-INCH')
set @Anul_inch=dbo.iauParN('PS','ANUL-INCH')
set @RegimLV=dbo.iauParL('PS','REGIMLV')
set @Somesana=dbo.iauParL('SP','SOMESANA')
set @Data=dbo.eom(convert(datetime,convert(char(2),(case when @luna_inch=12 then 1 else @luna_inch+1 end))+'/'+'01'+'/'+convert(char(4),(case when @luna_inch=12 then @Anul_inch+1 else @Anul_inch end)),101))
set @oreluna=isnull(convert(decimal(3),dbo.iauParLN(@Data,'PS','ORE_LUNA')),160)
if @oreluna=0 
	set @oreluna=170
set @pCassInd=convert(decimal(5,2),dbo.iauParLN(@Data,'PS','CASSIND'))
select @pCassInd=5.5 where @pCassInd=0

begin try  

	if exists (select 1 from sys.objects where name='wScriuSalariatiSP1' and type='P')  
		exec wScriuSalariatiSP1 @sesiune, @parXML output

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlpersonal') IS NOT NULL 
		drop table #xmlpersonal
	IF OBJECT_ID('tempdb..#personalFiltrat') IS NOT NULL 
		drop table #personalFiltrat

	select isnull(ptupdate, 0) as ptupdate, marca, isnull(marca_veche, marca) as marca_veche, nume, functie, lm, grupamunca, isnull(categoria_salarizare,'') as categoria_salarizare, 
	salinc, isnull(nullif(salbaza,0),salinc) as salbaza, reglucr, round(salinc/@oreluna,3) as salorar, tipsal, tipimp, pensie_suplimentara, 
	somaj, isnull(cassind,@pCassInd) as cassind, spindc, spvech, spnoapte, spprogr, spsupl, spspec, 
	sp1, sp2, sp3, sp4, sp5, sp6, sp7, sp8, sp9, sp10, sindicat, zileco, zilecosupl, luniproba, vechimean,
	vechimeluna, (case when vechimezi=0 then 1 else vechimezi end) as vechimezi, 
	convert(datetime,rtrim(convert(char(2),(case when vechimezi=0 then 1 else vechimezi end)))+'/'+(case when rtrim(convert(char(2),vechimeluna))='0' then '12' else rtrim(convert(char(2),vechimeluna)) end)+'/'+
	rtrim(convert(varchar(4),(case when vechimean=0 then 1899 else 1900+vechimean end)-(case when vechimean<>0 and vechimeluna=0 then 1 else 0 end))),103) as vechimemunca,
	rtrim(vechimeintrare) as vechimeintrare, rtrim(vechimemeserie) as vechimemeserie, 
	isnull(dataangajarii,'01/01/1901') as dataangajarii, banca, contbanca, 
	cnp, o_cnp, (case when (left(cnp,1)='1' or left(cnp,1)='5') then 1 else 0 end) as sex, 
	isnull(datanasterii,'1901-01-01') as datanasterii,
	casasan, buletin, plecat, localitate, judet, strada, numar, codpostal, bloc, scara, etaj, apart, isnull(modangaj,'N') as modangaj, 
	isnull(dataplec,'01/01/1901') as dataplec, dedpers, tipcolab, isnull(gradinv,'0') as gradinv, dedsomaj, altesurse, activitate, permis, limba, 
	nationalitatea, cetatenia, isnull(stareacivila,'N') as stareacivila, religia, isnull(stagiumilitar,'N') as stagiumilitar,
	telefon, email, observatii, actionar, nrcontract, tichete, anplimp, comanda, tipstat, pasaport, fictiv, detalii
	into #xmlpersonal
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii/row',
		ptupdate int '@update',
		marca_veche varchar(6) '@o_marca',
		marca varchar(6) '@marca',
		nume varchar(30) '@nume',
		functie varchar(6) '@functie',
		lm varchar(9) '@lm',
		grupamunca varchar(1) '@grupamunca',
		categoria_salarizare varchar(20) '@categs',
		salinc decimal(10) '@salinc',
		salbaza decimal(10) '@salbaza',
		reglucr decimal(5,2) '@reglucr',
		tipsal varchar(1) '@tipsal',
		tipimp varchar(1) '@tipimp',
		pensie_suplimentara varchar(1) '@pensiesupl',
		somaj decimal(4) '@somaj',
		cassind decimal(5,2) '@cassind',
		spindc decimal(8,2) '@spindc',
		spvech decimal(8,2) '@spvech',
		spnoapte decimal(8,2) '@spnoapte',
		spprogr decimal(8,2) '@spprogr',
		spsupl decimal(8,2) '@spsupl',
		spspec decimal(8,2) '@spspec',
		sp1 decimal(8,2) '@sp1',
		sp2 decimal(8,2) '@sp2',
		sp3 decimal(8,2) '@sp3',
		sp4 decimal(8,2) '@sp4',
		sp5 decimal(8,2) '@sp5',
		sp6 decimal(8,2) '@sp6',
		sp7 decimal(8,2) '@sp7',
		sp8 decimal(8,2) '@sp8',
		sp9 decimal(8,2) '@sp9',
		sp10 decimal(8,2) '@sp10',
		sindicat int '@sindicat',
		zileco decimal(4) '@zileco',
		zilecosupl decimal(4) '@zilecosupl',
		luniproba decimal(4) '@luniproba',
		vechimean decimal(4) '@vechimean',
		vechimeluna int '@vechimeluna',
		vechimezi int '@vechimezi',
		vechimeintrare char(6) '@vechimeintrare',
		vechimemeserie char(6) '@vechimemeserie',
		dataangajarii datetime '@dataangajarii',
		banca varchar(25) '@banca',
		contbanca varchar(25) '@contbanca',
		cnp varchar(13) '@cnp',
		o_cnp varchar(13) '@o_cnp',
		datanasterii datetime '@datanasterii',
		casasan varchar(30) '@casasan',
		buletin varchar(50) '@buletin',
		plecat int '@plecat',
		localitate varchar(30) '@localitate',
	--	judet varchar(15) '@denjudet',
		judet varchar(15) '@judet',
		strada varchar(25) '@strada',
		numar varchar(5) '@numar',
		codpostal int '@codpostal',
		bloc varchar(10) '@bloc',
		scara varchar(2) '@scara',
		etaj varchar(2) '@etaj',
		apart varchar(5) '@apart',
		modangaj varchar(1) '@modangaj',
		dataplec datetime '@dataplec',
		dedpers varchar(3) '@dedpers',
		tipcolab varchar(3) '@tipcolab',	
		gradinv varchar(1) '@gradinv',
		dedsomaj decimal(2) '@dedsomaj',
		altesurse int '@altesurse',
		activitate varchar(10) '@activitate',
		permis varchar(10) '@permis',
		limba varchar(30) '@limba',
		nationalitatea varchar(10) '@nationalitatea',
		cetatenia varchar(10) '@cetatenia',
		stareacivila varchar(1) '@stareacivila',
		religia varchar(10) '@religia',
		stagiumilitar varchar(1) '@stagiumilitar',
		telefon varchar(15) '@telefon',
		email varchar(50) '@email',
		observatii varchar(100) '@observatii',
		actionar int '@actionar',
		nrcontract varchar(20) '@nrcontract',
		tichete int '@tichete',
		anplimp char(9) '@anplimp',
		comanda varchar(20) '@comanda',
		tipstat varchar(25) '@tipstat',
		pasaport varchar(50) '@pasaport',
		fictiv int '@fictiv'	
	)
	exec sp_xml_removedocument @iDoc 

	while exists (select 1 from #xmlpersonal x where x.ptupdate=0 and isnull(x.marca, '')='')
	begin
		if @UltMarca is null
			set @UltMarca=isnull(convert(int,dbo.iauParN('PS','MARCA')),1)
		while exists (select 1 from personal where marca=RTrim(LTrim(convert(char(6), @UltMarca))))
			set @UltMarca = @UltMarca + 1
		update top (1) x
		set marca=RTrim(LTrim(convert(char(6), @UltMarca)))
		from #xmlpersonal x
		where x.ptupdate=0 and isnull(x.Marca, '')=''
		set @UltMarca = @UltMarca + 1
	end
	if @UltMarca is not null
		exec setare_par 'PS', 'MARCA', null, null, @UltMarca, null
	if exists (select 1 from #xmlpersonal where isnull(marca, '')='')
		raiserror('Marca necompletata!', 16, 1)
	if exists (select 1 from #xmlpersonal where isnull(nume, '')='')
		raiserror('Nume salariat necompletat!', 16, 1)
	if exists (select 1 from #xmlpersonal where isnull(functie, '')='')
		raiserror('Functie necompletata!', 16, 1)
	if exists (select 1 from #xmlpersonal where isnull(lm, '')='') and @Somesana=0
		raiserror('Loc de munca necompletat!', 16, 1)
	if exists (select 1 from #xmlpersonal where grupamunca='C' and isnull(reglucr, 0)=0)
		raiserror('Pentru un salariat cu contract de munca cu timp partial trebuie introdus regimul de lucru!', 16, 1)
	if exists (select 1 from #xmlpersonal where vechimeintrare<>'' and isnumeric(vechimeintrare)=0)
		raiserror('Campul vechime la intrare trebuie sa contina doar cifre!', 16, 1)

	select @reglucr=convert(decimal(5,2),x.reglucr), @cnp=cnp
	from #xmlpersonal x
	if exists (select 1 from #xmlpersonal where grupamunca in ('N','D','S') and isnull(reglucr, 0)>0 and isnull(reglucr, 0)<6)
	begin
		set @varmesaj='Un salariat cu regim de lucru de '+rtrim(convert(char(5),@reglucr))+' ore/zi trebuie incadrat pe conditii de munca C-contract de munca cu timp partial!'
		raiserror(@varmesaj, 16, 1)
	end
	if exists (select 1 from #xmlpersonal where grupamunca in ('N','D','S','C') and isnull(salinc, 0)=0)
		raiserror('Salarul de incadrare al salariatului necompletat!', 16, 1)

	select @marca=x.marca
	from #xmlpersonal x, personal p 
	where p.marca=x.marca and (x.ptupdate=0 or x.ptupdate=1 and x.marca<>x.marca_veche)
	if @marca is not null
	begin
		set @mesajEroare='Marca ' + RTrim(@marca) + ' este deja introdusa!'
		raiserror(@mesajEroare, 16, 1)
	end
	select @referinta=dbo.wfRefSalariati(x.marca_veche), 
		@marca=(case when @referinta>0 and @marca is null then x.marca_veche else @marca end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlpersonal x
	where x.ptupdate=1 and x.marca<>x.marca_veche

	if @marca is not null
	begin
		set @mesajEroare='Marca ' + RTrim(@marca) + ' are ' + (case @tabReferinta when 1 then 'retineri' 
		when 2 then 'avansuri exceptie' when 3 then 'concedii medicale' when 4 then 'concedii de odihna' 
		when 5 then 'pontaj' when 6 then 'corectii' when 7 then 'persoane in intretinere' 
		when 8 then 'tichete' when 9 then 'date in tabela brut' when 10 then 'date in tabela net' 
		when 11 then 'istoric de personal' else 'documente' end)+'!'
		raiserror(@mesajEroare, 16, 1)
	end
--	apelare validare CNP
	select @marca=x.marca, @detalii=x.detalii, @pasaport=x.pasaport
	from #xmlpersonal x
	exec wValidareCNP @CNP=@cnp, @Eroare=@eroare output, @Mesaj=@mesajEroare output, @DataCNP=@datanasterii output, @Sex=@sex output, @detalii=@detalii 
	if @eroare<>0
		raiserror(@mesajEroare, 16, 1)

--	atentionare daca salariatul nu a implinit 18 ani si a fost incadrat cu 8 ore/zi.
	if exists (select 1 from #xmlpersonal where grupamunca in ('N','D','S') and isnull(reglucr, 0)=8) and DateADD(year,18,@datanasterii)>getdate() --	salariatul nu are 18 ani
		select 'Salariatul este minor. Trebuie incadrat cu regim de lucru mai mic de 8 ore!' as textMesaj for xml raw, root('Mesaje')

--	atentionare daca CNP-ul introdus mai exista pe un alt salariat.
	if exists (select 1 from #xmlpersonal where ptupdate=0 or isnull(cnp,'')<>isnull(o_cnp,'')) 
	begin
		select top 1 @MarcaPeCNP=p.marca, @NumePeCNP=p.nume from personal p inner join #xmlpersonal x on x.cnp=p.cod_numeric_personal and x.Marca<>p.Marca
		if @MarcaPeCNP is not null
			select 'CNP-ul introdus mai exista in baza de date la marca: '+rtrim(@MarcaPeCNP)+' ('+rtrim(@NumePeCNP)+')'+'!' as textMesaj for xml raw, root('Mesaje')
	end

--	completare procent sanatate cu procentul configurat (5.5), la adaugare, pentru cei cu contract de munca sau ocazionali platitori CAS.
	update #xmlpersonal
		set cassind=@pCassInd
	where ptupdate=0 and cassind=0

--	corectie data plecarii la adaugare salariat (sa fie 01/01/1901, frame-ul trimite data sistem).
	update #xmlpersonal
		set dataplec='01/01/1901'
	where ptupdate=0 and modangaj<>'D' and dataplec<>'01/01/1901'

--	pentru locul de desfasurare al activitatii (din D205) nu pastram valoarea implicita=1 (activitate desfasurata in Romania)
	update #xmlpersonal set detalii.modify('delete (/row/@tipsalar205)[1]')
	where #xmlpersonal.detalii.value('(/row/@tipsalar205)[1]','varchar(100)')='1'

	update x
	set reglucr=(case when @RegimLV=1 or grupamunca='C' or reglucr<>0 then reglucr else 8 end),
	casasan=(case when nullif(casasan,'') is null then @pCasaSan else casasan end),
	tipcolab=(case when grupamunca in ('O','P') then tipcolab when dedpers='CDP' then '' else dedpers end),
	datanasterii=(case when datanasterii='01/01/1901' then @datanasterii else datanasterii end),sex=@sex
	from #xmlpersonal x
	if exists (select 1 from #xmlpersonal where isnull(casasan, '')='')
		raiserror('Casa de sanatate necompletata!', 16, 1)

--	calcul salar de baza in tabela temporara. Se va scrie salarul de baza in personal impreuna cu celelalte informatii.
	if object_id('tempdb..#personalSalBaza') is not null
		drop table #personalSalBaza
	Create table #personalSalBaza (marca varchar(6) not null)
	exec CreeazaDiezPersonal @numeTabela='#personalSalBaza'
	insert into #personalSalBaza
	select marca, salinc as salar_de_incadrare, salbaza as salar_de_baza, isnull(spindc,0) as indemnizatia_de_conducere, isnull(spspec,0) as spor_specific, 
		isnull(sp1,0) as spor_conditii_1, isnull(sp2,0) as spor_conditii_2, isnull(sp3,0) as spor_conditii_3, isnull(sp4,0) as spor_conditii_4, isnull(sp5,0) as spor_conditii_5, isnull(sp6,0) as spor_conditii_6
	from #xmlPersonal
	exec calculSalarDeBaza @sesiune=@sesiune, @parXML=@parXML
	update #xmlPersonal set salbaza=isnull(nullif(#personalSalBaza.salar_de_baza,0),#xmlPersonal.salbaza)
	from #personalSalBaza 
	where #personalSalBaza.marca=#xmlPersonal.marca

--	insert in personal
	insert into personal (marca,nume,cod_functie,loc_de_munca,loc_de_munca_din_pontaj,categoria_salarizare,grupa_de_munca,salar_de_incadrare,salar_de_baza,salar_lunar_de_baza,
	salar_orar,tip_salarizare,tip_impozitare,pensie_suplimentara,somaj_1,as_sanatate,Indemnizatia_de_conducere,
	Spor_vechime,Spor_de_noapte,Spor_sistematic_peste_program,Spor_de_functie_suplimentara,Spor_specific,
	Spor_conditii_1,Spor_conditii_2,Spor_conditii_3,Spor_conditii_4,Spor_conditii_5,Spor_conditii_6,
	Sindicalist,zile_concediu_de_odihna_an,zile_concediu_efectuat_an,zile_absente_an,vechime_totala,
	data_angajarii_in_unitate,banca,Cont_in_banca,poza,Sex,Data_nasterii,Cod_numeric_personal,
	Studii,Profesia,Adresa,copii,Loc_ramas_vacant,Localitate,Judet,Strada,Numar,Cod_postal,Bloc,Scara,Etaj,Apartament,Sector,Mod_angajare,Data_plec,Tip_colab,
	grad_invalid,coef_invalid,alte_surse,fictiv,detalii,Activitate,nr_contract,comanda,tip_stat,vechime_la_intrare,Spor_cond_7,Spor_cond_8,Spor_cond_9,Spor_cond_10)
	select marca, nume, functie, lm, isnull(tichete,0), categoria_salarizare, isnull(grupamunca,'N'), isnull(salinc,0), isnull(salbaza,0), 
	isnull(reglucr,8), isnull(salorar,0), isnull(tipsal,'1'), isnull(tipimp,'1'), isnull(pensie_suplimentara,0), isnull(somaj,1), 
	isnull(cassind,@pCassInd)*10, isnull(spindc,0), isnull(spvech,0), isnull(spnoapte,25), isnull(spprogr,0), isnull(spsupl,0), 
	isnull(spspec,0), isnull(sp1,0), isnull(sp2,0), isnull(sp3,0), isnull(Sp4,0), isnull(sp5,0), isnull(sp6,0),
	isnull(sindicat,0), isnull(zileco,21), isnull(zilecosupl,0), isnull(luniproba,0), isnull(vechimemunca,''), 
	isnull(dataangajarii,'1901-01-01'), isnull(banca,''), isnull(contbanca,''), null, isnull(sex,1),
	isnull(datanasterii,'1901-01-01'), isnull(cnp,''), '', '', isnull(casasan,''), isnull(buletin,''), isnull(plecat,0), 
	isnull(localitate,''), rtrim(isnull(judet,''))+(case when isnull(anplimp,'')<>'' then ','+rtrim(isnull(anplimp,'')) else '' end), 
	isnull(strada,''), isnull(numar,''), isnull(Codpostal,0), isnull(Bloc,''), isnull(Scara,''), isnull(etaj,''), isnull(apart,''), 0, 
	isnull(modangaj,'N'), isnull(dataplec,'1901-01-01'), isnull(tipcolab,''), isnull(gradinv,''), isnull(dedsomaj,0), isnull(altesurse,0), fictiv, detalii, activitate,
	nrcontract, comanda, tipstat, vechimeintrare, isnull(sp7,0), isnull(sp8,0), isnull(sp9,0), isnull(sp10,0)
	from #xmlpersonal x
	where x.ptupdate=0
/*
--	insert in infopers
	insert into infopers (marca,permis_auto_categoria,limbi_straine,nationalitatea,cetatenia,starea_civila,
	marca_sot_sotie,nume_sot_sotie,religia,evidenta_militara,telefon,email,observatii,actionar,
	centru_de_cost_exceptie,vechime_studii,poza,loc_munca_precedent,loc_munca_nou,
	vechime_la_intrare,vechime_in_meserie,nr_contract,spor_cond_7,spor_cond_8,spor_cond_9,spor_cond_10)
	select marca, isnull(permis,''), isnull(limba,''), isnull(nationalitatea,''), isnull(cetatenia,''), 
	isnull(stareacivila,'N'), '', '', isnull(religia,''), isnull(stagiumilitar,'N'),
	isnull(telefon,''), isnull(email,''), isnull(observatii,''), isnull(actionar,0), isnull(comanda,''), '', null, '', '', 
	isnull(vechimeintrare,''), isnull(vechimemeserie,''), isnull(nrcontract,''), isnull(sp7,0), isnull(sp8,0), isnull(sp9,0), isnull(sp10,0)
	from #xmlpersonal x
	where x.ptupdate=0 or not exists (select 1 from infopers ip where ip.marca=x.marca)
*/
--	update personal
	update p
	set Marca=isnull(x.marca, p.marca), 
	Nume=isnull(x.nume,p.Nume), Cod_functie=isnull(x.functie,p.Cod_functie), Loc_de_munca=isnull(x.lm,p.Loc_de_munca), Categoria_salarizare=isnull(x.categoria_salarizare,p.Categoria_salarizare), 
	Loc_de_munca_din_pontaj=isnull(x.tichete,p.Loc_de_munca_din_pontaj), Pensie_suplimentara=isnull(x.Pensie_suplimentara,p.Pensie_suplimentara), 
	Grupa_de_munca=isnull(x.grupamunca,p.Grupa_de_munca), Salar_de_incadrare=isnull(x.salinc,p.Salar_de_incadrare),
	Salar_de_baza=isnull(nullif(x.salbaza,0),p.Salar_de_baza), Salar_lunar_de_baza=isnull(x.reglucr,p.Salar_lunar_de_baza), 
	Salar_orar=isnull(x.salorar,p.Salar_orar), Tip_salarizare=isnull(x.tipsal,p.Tip_salarizare), 
	Tip_impozitare=isnull(x.tipimp,p.Tip_impozitare), Somaj_1=isnull(x.somaj,p.Somaj_1), As_sanatate=isnull(x.cassind*10,p.As_sanatate), 
	Indemnizatia_de_conducere=isnull(x.spindc,p.Indemnizatia_de_conducere),
	Spor_vechime=isnull(x.spvech,p.Spor_vechime), Spor_de_noapte=isnull(x.spnoapte,p.Spor_de_noapte),
	Spor_sistematic_peste_program=isnull(x.spprogr,p.Spor_sistematic_peste_program), Spor_de_functie_suplimentara=isnull(x.spsupl,p.Spor_de_functie_suplimentara),
	Spor_specific=isnull(x.spspec,p.Spor_specific), Spor_conditii_1=isnull(x.sp1,p.Spor_conditii_1), 
	Spor_conditii_2=isnull(x.sp2,p.Spor_conditii_2), Spor_conditii_3=isnull(x.sp3,p.Spor_conditii_3), Spor_conditii_4=isnull(x.sp4,p.Spor_conditii_4), 
	Spor_conditii_5=isnull(x.sp5,p.Spor_conditii_5), Spor_conditii_6=isnull(x.sp6,p.Spor_conditii_6), 
	Sindicalist=isnull(x.sindicat,p.Sindicalist), Zile_concediu_de_odihna_an=isnull(x.zileco,p.Zile_concediu_de_odihna_an), 
	Zile_concediu_efectuat_an=isnull(x.zilecosupl,p.Zile_concediu_efectuat_an),
	Zile_absente_an=isnull(x.luniproba,p.Zile_absente_an), Vechime_totala=isnull(x.vechimemunca,p.Vechime_totala), 
	Data_angajarii_in_unitate=isnull(x.dataangajarii,p.Data_angajarii_in_unitate), Banca=isnull(x.banca,p.Banca), 
	Cont_in_banca=isnull(x.contbanca,p.Cont_in_banca), Sex=isnull(x.sex,p.Sex), Data_nasterii=isnull(x.datanasterii,p.Data_nasterii),
	Cod_numeric_personal=isnull(x.cnp,p.Cod_numeric_personal), Adresa=isnull(x.casasan,p.Adresa), Copii=isnull(x.buletin,p.Copii),
	Loc_ramas_vacant=isnull(x.plecat,p.Loc_ramas_vacant), Localitate=isnull(x.localitate,p.Localitate), 
	Judet=isnull(rtrim(x.judet)+(case when isnull(x.anplimp,'')<>'' then ','+rtrim(isnull(x.anplimp,'')) else '' end),p.Judet), Strada=isnull(x.strada,p.Strada), 
	Numar=isnull(x.numar,p.Numar), Cod_postal=isnull(x.codpostal,p.Cod_postal),
	Bloc=isnull(x.bloc,p.Bloc), Scara=isnull(x.scara,p.Scara), Etaj=isnull(x.etaj,p.Etaj), Apartament=isnull(x.apart,p.Apartament), 
	Mod_angajare=isnull(x.Modangaj,p.Mod_angajare), Data_plec=isnull(x.Dataplec,p.Data_plec),
	Tip_colab=isnull(x.tipcolab,p.Tip_colab), Grad_invalid=isnull(x.gradinv,p.Grad_invalid), 
	Coef_invalid=isnull(x.dedsomaj,p.Coef_invalid), Alte_surse=isnull(x.altesurse,p.Alte_surse), fictiv=isnull(x.fictiv,p.fictiv), p.detalii=x.detalii, Activitate=isnull(x.Activitate,p.Activitate), 
	nr_contract=isnull(x.nrcontract,p.nr_contract), comanda=isnull(x.comanda,p.comanda), tip_stat=isnull(x.tipstat,p.tip_stat), Vechime_la_intrare=isnull(x.vechimeintrare,p.vechime_la_intrare), 
	Spor_cond_7=isnull(x.sp7,p.spor_cond_7), Spor_cond_8=isnull(x.sp8,p.spor_cond_8), Spor_cond_9=isnull(x.sp9,p.spor_cond_9), Spor_cond_10=isnull(x.sp10,p.spor_cond_10)
	from personal p, #xmlpersonal x
	where x.ptupdate=1 and p.marca=x.marca_veche
/*
--	update infopers
	update i
	set Marca=isnull(x.marca, i.marca), 
	Spor_cond_7=isnull(x.sp7,i.spor_cond_7), Spor_cond_8=isnull(x.sp8,i.spor_cond_8), Spor_cond_9=isnull(x.sp9,i.spor_cond_9), Spor_cond_10=isnull(x.sp10,i.spor_cond_10), 
	Permis_auto_categoria=isnull(x.permis,i.Permis_auto_categoria),
	Limbi_straine=isnull(x.limba,i.Limbi_straine), Nationalitatea=isnull(x.nationalitatea,i.Nationalitatea), 
	Cetatenia=isnull(x.cetatenia,i.Cetatenia), Starea_civila=isnull(x.stareacivila,i.Starea_civila), 
	Religia=isnull(x.Religia,i.Religia), Evidenta_militara=isnull(x.stagiumilitar,i.Evidenta_militara), 
	Telefon=isnull(x.telefon,i.Telefon), Email=isnull(x.email,i.Email), Observatii=isnull(x.observatii,i.Observatii),
	Actionar=isnull(x.actionar,i.Actionar), Centru_de_cost_exceptie=isnull(x.comanda,i.Centru_de_cost_exceptie), 
	Vechime_la_intrare=isnull(x.vechimeintrare,i.Vechime_la_intrare), Vechime_in_meserie=isnull(x.vechimemeserie,i.Vechime_in_meserie), 
	Nr_contract=isnull(x.nrcontract,i.Nr_contract)
	from infopers i, #xmlPersonal x
	where x.ptupdate=1 and i.Marca=x.Marca_veche
*/
	if @pasaport is not null
		exec scriuExtinfop @Marca=@marca, @Cod_inf='PASAPORT', @Val_inf=@pasaport, @Data_inf='01/01/1901', @Procent=0, @Stergere=2

	if exists (select 1 from sys.objects where name='wScriuSalariatiSP2' and type='P')  
		exec wScriuSalariatiSP2 @sesiune, @parXML output

	if @codMeniu in ('SDS','SDPS')
	begin
		select @marca=marca, @ptupdate=ptupdate
		from #xmlpersonal
		
		if @ptupdate=1 and @tip<>''
			select 0 as 'close' for xml raw, root('Mesaje')

		declare @parXMLIa xml
		set @parXMLIa='<row marca="'+rtrim(@marca)+'" />'
		exec wIaSalariati @sesiune=@sesiune, @parXML=@parXMLIa
	end

end try  

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

IF OBJECT_ID('tempdb..#xmlpersonal') IS NOT NULL drop table #xmlpersonal
