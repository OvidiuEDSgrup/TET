--***
Create procedure wScriuClaseSalarizare @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @clasasal varchar(6), @descriere varchar(200), @salar_lunar decimal(12,3), @coeficient decimal(12,3),
@referinta int, @tabReferinta int, @eroare xml, @mesaj varchar(254), @mesajEroare varchar(254)

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlclasasal') IS NOT NULL
	drop table #xmlclasasal

begin try  
	--BEGIN TRAN
	select isnull(ptupdate, 0) as ptupdate, clasasal, isnull(o_clasasal, clasasal) as o_clasasal, descriere, salar_lunar, coeficient
	into #xmlclasasal
	from OPENXML(@iDoc, '/row')
	WITH
	(
		ptupdate int '@update',
		clasasal varchar(20) '@clasasal',
		o_clasasal varchar(20) '@o_clasasal',
		descriere varchar(30) '@descriere',
		salar_lunar float '@salarlunar',
		coeficient float '@coeficient'
	)
	exec sp_xml_removedocument @iDoc 

--	atribuire clasa la adaugare clasa de salarizare 
	while exists (select 1 from #xmlclasasal x where x.ptupdate=0 and isnull(x.clasasal, '')='')
	begin
		declare @UltCategSal varchar(6)
		if (@clasasal is null)
			exec wmaxcod 'Categoria_salarizare','categs',@UltCategSal output
		if @UltCategSal is null
			set @UltCategSal=1
		update top (1) x
		set clasasal=RTrim(LTrim(convert(char(9), @UltCategSal)))
		from #xmlclasasal x
		where x.ptupdate=0 and isnull(x.clasasal, '')=''
	End

--	validari
	if exists (select 1 from #xmlclasasal where isnull(clasasal, '')='')
		raiserror('Clasa salarizare necompletata!', 16, 1)
	if exists (select 1 from #xmlclasasal where isnull(descriere, '')='')
		raiserror('Descriere clasa salarizare necompletata!', 16, 1)

	select @clasasal=x.clasasal
	from #xmlclasasal x, categs c
	where c.Categoria_salarizare=x.clasasal and (x.ptupdate=0 or x.ptupdate=1 and x.clasasal<>x.o_clasasal)
	if @clasasal is not null
	begin
		set @mesajEroare='Clasa de salarizare ' + RTrim(@clasasal) + ' este deja introdusa!'
		raiserror(@mesajEroare, 16, 1)
	end
	select @referinta=dbo.wfRefFunctii(x.o_clasasal), 
		@clasasal=(case when @referinta>0 and @clasasal is null then x.o_clasasal else @clasasal end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlclasasal x
	where x.ptupdate=1 and x.clasasal<>x.o_clasasal
	if @clasasal is not null
	begin
		set @mesajEroare='Clasa de salarizare ' + RTrim(@clasasal) + ' apare in ' + (case @tabReferinta when 1 then 'salariati!' when 2 then 'istoric salariati!' else '' end)
		raiserror(@mesajEroare, 16, 1)
	end

	insert into categs (Categoria_salarizare, Descriere, Salar_lunar, Salar_orar)
	select x.clasasal, isnull(x.descriere,''), isnull(x.salar_lunar,0), isnull(x.coeficient,0)
	from #xmlclasasal x
	where x.ptupdate=0

	update c
	set c.Categoria_salarizare=isnull(x.clasasal, c.Categoria_salarizare), c.Descriere=isnull(x.descriere,c.descriere), 
		c.Salar_lunar=isnull(x.Salar_lunar,c.Salar_lunar), c.Salar_orar=isnull(x.coeficient,c.Salar_orar)
	from categs c, #xmlclasasal x
	where x.ptupdate=1 and c.Categoria_salarizare=x.o_clasasal

	--COMMIT TRAN
end try  
Begin catch
	--ROLLBACK TRAN
	set @mesaj=ERROR_MESSAGE()+' (wScriuClaseSalarizare)'
	raiserror(@mesaj, 11, 1)
End catch

IF OBJECT_ID('tempdb..#xmlclasasal') IS NOT NULL
	drop table #xmlclasasal
