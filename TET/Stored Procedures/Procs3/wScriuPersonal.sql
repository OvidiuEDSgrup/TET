--***
Create procedure wScriuPersonal @sesiune varchar(50), @parXML xml
as 

Declare @tip varchar(2), @sub varchar(9), @iDoc int, @ptupdate int, @o_marca varchar(6), @marca varchar(6), @functie varchar(100), @parXMLFunctii xml, 
@cnp varchar(13), @datanasterii datetime, @sex int, @reglucr decimal(5,2), @pCassInd decimal(5,2), @pCasaSan varchar(20), 
@UltMarca varchar(6), @Luna_inch int, @Anul_inch int, @Data datetime, @detalii xml, 
@referinta int, @tabReferinta int, @eroare int, @mesaj varchar(254), @mesajEroare varchar(254), @varmesaj varchar(254)

set @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),'')
set @sub=dbo.iauParA('GE','SUBPRO')
set @pCasaSan=dbo.iauParA('PS','CODJUDETA')
set @Luna_inch=dbo.iauParN('PS','LUNA-INCH')
set @Anul_inch=dbo.iauParN('PS','ANUL-INCH')
set @Data=dbo.eom(convert(datetime,convert(char(2),(case when @luna_inch=12 then 1 else @luna_inch+1 end))+'/'+'01'+'/'+convert(char(4),(case when @luna_inch=12 then @Anul_inch+1 else @Anul_inch end)),101))
set @pCassInd=convert(decimal(5,2),dbo.iauParLN(@Data,'PS','CASSIND'))
select @pCassInd=5.5 where @pCassInd=0

begin try  

if exists (select 1 from sys.objects where name='wScriuPersonalSP1' and type='P')  
	exec wScriuPersonalSP1 @sesiune, @parXML output

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlpersonal') IS NOT NULL drop table #xmlpersonal

select isnull(ptupdate, 0) as ptupdate, marca, isnull(marca_veche, marca) as marca_veche, nume, functie, lm, 
isnull(dataangajarii,'01/01/1901') as dataangajarii, banca, contbanca, 
cnp, (case when (left(cnp,1)='1' or left(cnp,1)='5') then 1 else 0 end) as sex, 
isnull(datanasterii,'1901-01-01') as datanasterii,
buletin, plecat, localitate, judet, strada, numar, codpostal, bloc, scara, etaj, apart, 
isnull(dataplec,'01/01/1901') as dataplec, fictiv, detalii, RTRIM(observatii) observatii
into #xmlpersonal
from OPENXML(@iDoc, '/row')
WITH
(
	detalii xml 'detalii/row',
	ptupdate int '@update',
	marca_veche varchar(6) '@o_marca',
	marca varchar(6) '@marca',
	nume varchar(30) '@nume',
	functie varchar(100) '@functie',
	lm varchar(9) '@lm',
	dataangajarii datetime '@dataangajarii',
	banca varchar(25) '@banca',
	contbanca varchar(25) '@contbanca',
	cnp varchar(13) '@cnp',
	datanasterii datetime '@datanasterii',
	buletin varchar(50) '@buletin',
	plecat int '@plecat',
	localitate varchar(30) '@localitate',
	judet varchar(15) '@judet',
	strada varchar(25) '@strada',
	numar varchar(5) '@numar',
	codpostal int '@codpostal',
	bloc varchar(10) '@bloc',
	scara varchar(2) '@scara',
	etaj varchar(2) '@etaj',
	apart varchar(5) '@apart',
	dataplec datetime '@dataplec',
	fictiv int '@fictiv',
	observatii varchar(50) '@observatii'	
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
	if exists (select 1 from #xmlpersonal where isnull(lm, '')='')
		raiserror('Loc de munca necompletat!', 16, 1)

--daca functia introdusa nu exista in catalogul de personal, o adaug automat cu denumirea introdusa 
	if not exists (select 1 from #xmlpersonal x inner join functii f on f.cod_functie=x.functie) 
		and exists (select 1 from #xmlpersonal x where isnumeric(x.functie)=0) 
	begin
		select @functie=functie from #xmlpersonal x
		if not exists (select 1 from functii f where denumire like '%'+rtrim(@functie))
		begin
			set @parXMLFunctii=(select @functie as denumire for xml raw)
			exec wScriuFunctii @sesiune=@sesiune, @parXML=@parXMLFunctii
		end
		set @functie=(select top 1 cod_functie from functii where denumire like '%'+rtrim(@functie) order by denumire)
		update #xmlpersonal set functie=@functie
	end	

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

	if exists (select 1 from deconturi where Subunitate=@sub and marca=@Marca)
		set @tabReferinta=15
	if exists (select 1 from stocuri where Subunitate=@sub and Tip_gestiune='F' and Cod_gestiune=@Marca)
		set @tabReferinta=16

	if @marca is not null
	begin
		set @mesajEroare='Marca ' + RTrim(@marca) + ' are ' + 
		(case @tabReferinta when 1 then 'retineri' when 2 then 'avansuri exceptie' 
			when 3 then 'concedii medicale' when 4 then 'concedii de odihna' when 5 then 'pontaj' 
			when 6 then 'corectii' when 7 then 'persoane in intretinere' when 8 then 'tichete' 
			when 9 then 'date in tabela brut' when 10 then 'date in tabela net' when 11 then 'istoric de personal' 
			when 15 then 'deconturi' when 16 then 'stocuri in folosinta' else 'documente' end)+'!'
		raiserror(@mesajEroare, 16, 1)
	end
--	apelare validare CNP
	select @detalii=x.detalii, @cnp=cnp
	from #xmlpersonal x
	exec wValidareCNP @CNP=@cnp, @Eroare=@eroare output, @Mesaj=@mesajEroare output, @DataCNP=@datanasterii output, @Sex=@sex output, @detalii=@detalii 
	if @eroare<>0
		raiserror(@mesajEroare, 16, 1)

	update x set datanasterii=(case when datanasterii='01/01/1901' then @datanasterii else datanasterii end),sex=@sex
	from #xmlpersonal x

--	insert in personal
	insert into personal (marca,nume,cod_functie,loc_de_munca,loc_de_munca_din_pontaj,categoria_salarizare,grupa_de_munca,
	salar_de_incadrare,salar_de_baza,salar_lunar_de_baza,salar_orar,tip_salarizare,tip_impozitare,
	pensie_suplimentara,somaj_1,as_sanatate,Indemnizatia_de_conducere,
	Spor_vechime,Spor_de_noapte,Spor_sistematic_peste_program,Spor_de_functie_suplimentara,Spor_specific,
	Spor_conditii_1,Spor_conditii_2,Spor_conditii_3,Spor_conditii_4,Spor_conditii_5,Spor_conditii_6,
	Sindicalist,zile_concediu_de_odihna_an,zile_concediu_efectuat_an,zile_absente_an,vechime_totala,
	Data_angajarii_in_unitate,banca,Cont_in_banca,poza,Sex,Data_nasterii,Cod_numeric_personal,
	Studii,Profesia,Adresa,Copii,Loc_ramas_vacant,Localitate,Judet,Strada,Numar,
	Cod_postal,Bloc,Scara,Etaj,Apartament,Sector,Mod_angajare,Data_plec,Tip_colab,
	grad_invalid,coef_invalid,alte_surse,fictiv,detalii)  
	select marca, nume, functie, lm, 0, '', 'N', 0, 0, 8, 0, '1', '1', 0, 1, 
	@pCassInd*10, 0, 0, 25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0, '', 
	isnull(dataangajarii,'1901-01-01'), isnull(banca,''), isnull(contbanca,''), null, isnull(sex,1),
	isnull(datanasterii,'1901-01-01'), isnull(cnp,''), '', '', @pCasaSan, isnull(buletin,''), isnull(plecat,1), 
	isnull(localitate,''), isnull(judet,''), isnull(strada,''), isnull(numar,''), isnull(Codpostal,0), 
	isnull(Bloc,''), isnull(Scara,''), isnull(etaj,''), isnull(apart,''), 0, 
	'N', isnull(dataplec,'1901-01-01'), '', '', 0, 0, isnull(fictiv,1), detalii
	from #xmlpersonal x
	where x.ptupdate=0 and not exists (select 1 from personal p where p.marca=x.marca)

--	insert in infopers
	insert into infopers (marca,permis_auto_categoria,limbi_straine,nationalitatea,cetatenia,starea_civila,
	marca_sot_sotie,nume_sot_sotie,religia,evidenta_militara,telefon,email,observatii,actionar,
	centru_de_cost_exceptie,vechime_studii,poza,loc_munca_precedent,loc_munca_nou,vechime_la_intrare,
	vechime_in_meserie,nr_contract,spor_cond_7,spor_cond_8,spor_cond_9,spor_cond_10)
	select marca, '', '', '', '', 'N', '', '', '', 'N', '', '', ISNULL(observatii,''), 0, '', '', null, '', '', '', '', '', 0, 0, 0, 0
	from #xmlpersonal x
	where x.ptupdate=0 and not exists (select 1 from infopers ip where ip.marca=x.marca)

--	update personal
	update p
	set Marca=isnull(x.marca, p.marca), 
	Nume=isnull(x.nume,p.Nume), Cod_functie=isnull(x.functie,p.Cod_functie), Loc_de_munca=isnull(x.lm,p.Loc_de_munca),
	Data_angajarii_in_unitate=isnull(x.dataangajarii,p.Data_angajarii_in_unitate), Banca=isnull(x.banca,p.Banca), 
	Cont_in_banca=isnull(x.contbanca,p.Cont_in_banca), Sex=isnull(x.sex,p.Sex), Data_nasterii=isnull(x.datanasterii,p.Data_nasterii),
	Cod_numeric_personal=isnull(x.cnp,p.Cod_numeric_personal), Copii=isnull(x.buletin,p.Copii),
	Loc_ramas_vacant=isnull(x.plecat,p.Loc_ramas_vacant), Localitate=isnull(x.localitate,p.Localitate), 
	Judet=isnull(rtrim(x.judet),p.Judet), Strada=isnull(x.strada,p.Strada), Numar=isnull(x.numar,p.Numar), Cod_postal=isnull(x.codpostal,p.Cod_postal),
	Bloc=isnull(x.bloc,p.Bloc), Scara=isnull(x.scara,p.Scara), Etaj=isnull(x.etaj,p.Etaj), Apartament=isnull(x.apart,p.Apartament), 
	Data_plec=isnull(x.Dataplec,p.Data_plec),fictiv=isnull(x.fictiv,p.fictiv), p.detalii=x.detalii
	from personal p, #xmlpersonal x
	where x.ptupdate=1 and p.marca=x.marca_veche

	update ip
		set observatii=ISNULL(x.observatii, ip.Observatii)
	from infopers ip, #xmlpersonal x
	where x.ptupdate=1 and ip.marca=x.marca_veche

	if exists (select 1 from sys.objects where name='wScriuPersonalSP2' and type='P')  
		exec wScriuPersonalSP2 @sesiune, @parXML output

end try  

begin catch
	set @mesaj=ERROR_MESSAGE()+' (wScriuPersonal)'
	raiserror(@mesaj, 11, 1)
end catch

IF OBJECT_ID('tempdb..#xmlpersonal') IS NOT NULL drop table #xmlpersonal
