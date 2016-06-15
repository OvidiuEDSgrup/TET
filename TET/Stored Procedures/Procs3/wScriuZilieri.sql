/*
	Procedura pt. scriere in catalogul de zilieri
*/
Create 
procedure wScriuZilieri (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuZilieriSP')
	begin
		declare @returnValue int
		exec @returnValue=wScriuZilieriSP @sesiune, @parXML output
		return @returnValue
	end

begin try
	declare @iDoc int, @utilizator char(20), @mesaj varchar(80),@ptupdate int, @eroare int,
	@UltMarca varchar(6),@o_marca varchar(6), @marca varchar(6), @nume varchar(50), @functie char(30), @lm char(9),
	@cnp varchar(13), @datanasterii datetime, @sex bit

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlpersonal') IS NOT NULL
		drop table #xmlpersonal

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select marca,nume,codfct,lm,denlm,salinc,salor,tipsal,denfct,comanda,isnull(dataangajarii,'01/01/1901') as dataangajarii,
		plecat,isnull(dataplecarii,'01/01/1901') as dataplecarii,banca,contbanca,
		cnp,isnull(datanasterii,'1901-01-01') as datanasterii,(case when (left(cnp,1)='1' or left(cnp,1)='5') then 1 else 0 end) as sex,
		buletin,dataeliberarii,localitate,idlocalitate,judet,codpostal,strada,numar,bloc,scara,etaj,
		apartament,sector,ptupdate,isnull(o_marca, marca) as o_marca
	into #xmlpersonal
	from OPENXML(@iDoc, '/row')
	WITH
	(marca varchar(6) '@marca',
	nume varchar(50) '@nume',
	codfct varchar(6) '@codfct',
	lm varchar(9)'@lm',
	denlm varchar(30)'@denlm',
	salinc float '@salinc',
	salor float '@salor',
	tipsal char(1) '@tipsal',
	denfct varchar(30) '@denfct',
	comanda varchar(20) '@comanda',
	dataangajarii datetime '@dataangajarii',
	plecat bit '@plecat',
	dataplecarii datetime '@dataplecarii',
	banca varchar(25) '@banca',
	contbanca varchar(25) '@contbanca',
	cnp char(13) '@cnp',
	datanasterii datetime '@datanasterii',
	sex bit '@sex',
	buletin varchar(30) '@buletin',
	dataeliberarii datetime '@dataeliberarii',
	localitate varchar(30) '@localitate', 
	idlocalitate int '@idlocalitate',
	judet varchar(15) '@judet',
	codpostal int '@codpostal',
	strada varchar(25) '@strada',
	numar varchar(5) '@numar',
	bloc varchar(10) '@bloc',
	scara varchar(2) '@scara',
	etaj varchar(2) '@etaj',
	apartament varchar(5) '@apartament',
	sector smallint '@sector',
	ptupdate int '@update',
	o_marca varchar(6) '@o_marca')

	update #xmlpersonal
	set ptupdate=ISNULL(ptupdate,0) 
	exec sp_xml_removedocument @iDoc 
	--generare marca
	while exists (select 1 from #xmlpersonal x where x.ptupdate=0 and isnull(x.marca, '')='')
	begin
		if @UltMarca is null
			set @UltMarca=isnull(convert(int,dbo.iauParN('PS','MARCAZIL')),1)
		while exists (select 1 from personal where marca=RTrim(LTrim(convert(char(6), @UltMarca))))
			set @UltMarca = @UltMarca + 1
		update top (1) x
		set marca=RTrim(LTrim(convert(char(6), @UltMarca)))
		from #xmlpersonal x
		where x.ptupdate=0 and isnull(x.Marca, '')=''
		set @UltMarca = @UltMarca + 1
	end
	if @UltMarca is not null
		exec setare_par 'PS', 'MARCAZIL', null, null, @UltMarca, null
	
--	validari
	if exists (select 1 from #xmlpersonal where isnull(marca, '')='')
		raiserror('Marca necompletata!', 16, 1)
	if exists (select 1 from #xmlpersonal where isnull(nume, '')='')
		raiserror('Nume zilier necompletat!', 16, 1)
	if exists (select 1 from #xmlpersonal where isnull(lm, '')='')
		raiserror('Loc de munca necompletat!', 16, 1)
	if exists (select 1 from #xmlpersonal where isnull(codfct, '')='')
		raiserror('Functie necompletata!', 16, 1)
	if not exists(select 1 from #xmlpersonal x inner join lm l on x.lm=l.cod) 
		raiserror('Loc de munca inexistent!', 16, 1)
	if not exists(select 1 from #xmlpersonal x inner join functii f on x.codfct=f.cod_functie) 
		raiserror('Functie inexistenta!', 16, 1)
	if exists (select 1 from #xmlpersonal where isnull(comanda,'')!='') and not exists(select 1 from #xmlpersonal x inner join comenzi c on x.comanda=c.comanda) 
		raiserror('Comanda inexistenta!', 16, 1) 						
	if (select localitate from #xmlpersonal)!='Bucuresti' and exists (select 1 from #xmlpersonal where isnull(sector,0)!=0)
		raiserror('Sectorul nu trebuie specificat!',16,1)
	if (exists (select 1 from #xmlpersonal where ISNULL(dataangajarii,'')='' ) or exists (select 1 from #xmlpersonal where dataangajarii='01/01/1900'))
		select 'Atentie, data angajarii necompletata!' as textMesaj for xml raw, root('Mesaje')
	if exists(select 1 from #xmlpersonal where ISNULL(salor,0)=0 )
		select 'Atentie, salar orar necompletat!' as textMesaj for xml raw, root('Mesaje')
	select @cnp=cnp from #xmlpersonal x
	
--	validare CNP
	exec wValidareCNP @cnp, @eroare output, @mesaj output, @datanasterii output, @sex output
	if @eroare=2
	begin 
		raiserror(@mesaj,11,1)
		return -1
	end
	else 
	if @eroare=1
	begin
		raiserror(@mesaj,11,1)
		return -1
	end
	update x
	set datanasterii=(case when datanasterii='01/01/1901' then @datanasterii else datanasterii end),sex=@sex
	from #xmlpersonal x
	
--	adaugare
	insert into Zilieri(Marca,Nume,Cod_functie,Loc_de_munca,Comanda,Salar_de_incadrare,Tip_salar_orar,Salar_orar,Data_angajarii,Plecat,Data_plecarii,Banca,Cont_in_banca,Cod_numeric_personal,Data_nasterii,Sex,Buletin,Data_eliberarii,Localitate,Judet,Strada,Numar,Cod_postal,Bloc,Scara,Etaj,Apartament,Sector)
	select marca,nume,codfct,lm,comanda,isnull(salinc,0),tipsal,isnull(salor,0),isnull(dataangajarii,'1901-01-01'),
		isnull(plecat,0),isnull(dataplecarii,'1901-01-01'),isnull(banca,''),isnull(contbanca,''),cnp,
		isnull(datanasterii,'1901-01-01'),sex,isnull(buletin,''),isnull(dataeliberarii,'1901-01-01'),
		isnull(localitate,''),ISNULL(judet,''),isnull(strada,''),isnull(numar,''),isnull(codpostal,''),
		isnull(bloc,''),isnull(scara,''),isnull(etaj,''),isnull(apartament,''),isnull(sector,'')
	from #xmlpersonal x
	where x.ptupdate=0
	
--	modificare
	update Zilieri 
	set Nume=isnull(x.nume,z.nume), Cod_functie=ISNULL(x.codfct,z.Cod_functie), Loc_de_munca=ISNULL(x.lm,z.Loc_de_munca),
		Comanda=ISNULL(x.comanda,z.comanda),Salar_de_incadrare=ISNULL(x.salinc,z.Salar_de_incadrare),Tip_salar_orar=ISNULL(x.tipsal,z.Tip_salar_orar),
		Salar_orar=ISNULL(x.salor,z.salar_orar), Data_angajarii=convert(datetime,ISNULL(x.dataangajarii,z.data_angajarii)), Plecat=ISNULL(x.plecat,z.plecat),
		Data_plecarii=convert(datetime,ISNULL(x.dataplecarii,z.data_plecarii)),Banca=ISNULL(x.banca,z.banca),Cont_in_banca=ISNULL(x.contbanca,z.Cont_in_banca),
		Cod_numeric_personal=ISNULL(x.cnp,z.Cod_numeric_personal), Data_nasterii=convert(datetime,isnull(x.datanasterii,z.data_nasterii)),Sex=ISNULL(x.sex,z.sex),
		Buletin=ISNULL(x.buletin,z.buletin), Data_eliberarii=convert(datetime,ISNULL(x.dataeliberarii,z.data_eliberarii)),Localitate=ISNULL(x.localitate,z.localitate),
		Judet=ISNULL(x.judet,z.judet), Strada=ISNULL(x.strada,z.strada),Numar=ISNULL(x.numar,z.numar),Cod_postal=ISNULL(x.codpostal,z.cod_postal),
		Bloc=ISNULL(x.bloc,z.bloc),Scara=ISNULL(x.scara,z.scara), Etaj=ISNULL(x.etaj,z.etaj), Apartament=ISNULL(x.apartament,z.apartament),
		Sector=ISNULL(x.sector,z.sector)
	from zilieri z, #xmlpersonal x
	where x.ptupdate=1 and z.marca=x.o_marca
end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1) 
end catch
