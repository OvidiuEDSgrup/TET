--***
Create procedure wScriuCategoriiSalarizare @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @categsal varchar(6), @descriere varchar(200), @salar_lunar decimal(12,3), @salar_orar decimal(12,3),
@referinta int, @tabReferinta int, @eroare xml, @mesaj varchar(254), @mesajEroare varchar(254)

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlcategsal') IS NOT NULL
	drop table #xmlcategsal

begin try  
	--BEGIN TRAN
	select isnull(ptupdate, 0) as ptupdate, categsal, isnull(o_categsal, categsal) as o_categsal, descriere, salar_lunar, salar_orar
	into #xmlcategsal
	from OPENXML(@iDoc, '/row')
	WITH
	(
		ptupdate int '@update',
		categsal varchar(20) '@categsal',
		o_categsal varchar(20) '@o_categsal',
		descriere varchar(30) '@descriere',
		salar_lunar float '@salarlunar',
		salar_orar float '@salarorar'
	)
	exec sp_xml_removedocument @iDoc 

--	atribuire cod categorie la adaugare categorie de salarizare 
	while exists (select 1 from #xmlcategsal x where x.ptupdate=0 and isnull(x.categsal, '')='')
	begin
		declare @UltCategSal varchar(6)
		if (@categsal is null)
			exec wmaxcod 'Categoria_salarizare','categs',@UltCategSal output
		if @UltCategSal is null
			set @UltCategSal=1
		update top (1) x
		set categsal=RTrim(LTrim(convert(char(9), @UltCategSal)))
		from #xmlcategsal x
		where x.ptupdate=0 and isnull(x.categsal, '')=''
	End

--	validari
	if exists (select 1 from #xmlcategsal where isnull(categsal, '')='')
		raiserror('Categorie salarizare necompletata!', 16, 1)
	if exists (select 1 from #xmlcategsal where isnull(descriere, '')='')
		raiserror('Descriere categorie salarizare necompletata!', 16, 1)

	select @categsal=x.categsal
	from #xmlcategsal x, categs c
	where c.Categoria_salarizare=x.categsal and (x.ptupdate=0 or x.ptupdate=1 and x.categsal<>x.o_categsal)
	if @categsal is not null
	begin
		set @mesajEroare='Categoria de salarizare ' + RTrim(@categsal) + ' este deja introdusa!'
		raiserror(@mesajEroare, 16, 1)
	end
	select @referinta=dbo.wfRefFunctii(x.o_categsal), 
		@categsal=(case when @referinta>0 and @categsal is null then x.o_categsal else @categsal end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlcategsal x
	where x.ptupdate=1 and x.categsal<>x.o_categsal
	if @categsal is not null
	begin
		set @mesajEroare='Categoria de salarizare ' + RTrim(@categsal) + ' apare in ' + (case @tabReferinta when 1 then 'salariati!' when 2 then 'istoric salariati!' else '' end)
		raiserror(@mesajEroare, 16, 1)
	end

	insert into categs (Categoria_salarizare, Descriere, Salar_lunar, Salar_orar)
	select x.categsal, isnull(x.descriere,''), isnull(x.salar_lunar,0), isnull(x.salar_orar,0)
	from #xmlcategsal x
	where x.ptupdate=0

	update c
	set c.Categoria_salarizare=isnull(x.categsal, c.Categoria_salarizare), c.Descriere=isnull(x.descriere,c.descriere), 
		c.Salar_lunar=isnull(x.Salar_lunar,c.Salar_lunar), c.Salar_orar=isnull(x.Salar_orar,c.Salar_orar)
	from categs c, #xmlcategsal x
	where x.ptupdate=1 and c.Categoria_salarizare=x.o_categsal

	--COMMIT TRAN
end try  
Begin catch
	--ROLLBACK TRAN
	set @mesaj=ERROR_MESSAGE()+' (wScriuCategoriiSalarizare)'
	raiserror(@mesaj, 11, 1)
End catch

IF OBJECT_ID('tempdb..#xmlcategsal') IS NOT NULL
	drop table #xmlcategsal
