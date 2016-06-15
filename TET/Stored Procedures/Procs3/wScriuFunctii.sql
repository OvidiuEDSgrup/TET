--***
Create procedure wScriuFunctii @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @cod varchar(6), @descriere varchar(200), @scop varchar(200), @studii varchar(200), @experienta varchar(200), @id_domeniu int, @referinta int, @tabReferinta int, 
@eroare xml, @mesaj varchar(254), @mesajEroare varchar(254), @detalii xml, @docDetalii xml

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlfunctii') IS NOT NULL
	drop table #xmlfunctii

begin try  
	--BEGIN TRAN
	select isnull(ptupdate, 0) as ptupdate, cod, isnull(o_cod, cod) as o_cod, denumire, nivel_studii, numarcor, codcor, descriere, scop, studii, experienta, id_domeniu,
		o_descriere, o_scop, o_studii, o_experienta, o_id_domeniu, detalii
	into #xmlfunctii
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii',
		ptupdate int '@update', 
		cod varchar(6) '@cod',
		o_cod varchar(6) '@o_cod',
		denumire varchar(30) '@denumire',
		nivel_studii varchar(10) '@nivelstudii',
		numarcor varchar(10) '@numarcor',
		codcor varchar(10) '@codcor',
		descriere varchar(200) '@descriere',
		scop varchar(200) '@scop',
		studii varchar(200) '@studii',
		experienta varchar(200) '@experienta',
		id_domeniu int '@id_domeniu',	
		o_descriere varchar(200) '@o_descriere',
		o_scop varchar(200) '@o_scop',
		o_studii varchar(200) '@o_studii',
		o_experienta varchar(200) '@o_experienta',
		o_id_domeniu int '@o_id_domeniu'
	)
	exec sp_xml_removedocument @iDoc 

--	atribuire cod functie la adaugare functie
	while exists (select 1 from #xmlfunctii x where x.ptupdate=0 and isnull(x.cod, '')='')
	begin
		declare @UltFunctie varchar(6)
		if (@cod is null)  	
			exec wmaxcod 'Cod_functie','functii',@UltFunctie output
		if @UltFunctie is null
			set @UltFunctie=1
		update top (1) x
		set Cod=RTrim(LTrim(convert(char(9), @UltFunctie)))
		from #xmlfunctii x
		where x.ptupdate=0 and isnull(x.Cod, '')=''
	End
--	validari
	if exists (select 1 from #xmlfunctii where isnull(cod, '')='')
		raiserror('Cod functie necompletat!', 16, 1)
	if exists (select 1 from #xmlfunctii where isnull(denumire, '')='')
		raiserror('Denumire functie necompletata!', 16, 1)

	select @cod=x.cod
	from #xmlfunctii x, functii f 
	where f.Cod_functie=x.cod and (x.ptupdate=0 or x.ptupdate=1 and x.cod<>x.o_cod)
	if @cod is not null
	begin
		set @mesajEroare='Functia ' + RTrim(@cod) + ' este deja introdusa!'
		raiserror(@mesajEroare, 16, 1)
	end
	select @referinta=dbo.wfRefFunctii(x.o_cod), 
		@cod=(case when @referinta>0 and @cod is null then x.o_cod else @cod end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlfunctii x
	where x.ptupdate=1 and x.cod<>x.o_cod
	if @cod is not null
	begin
		set @mesajEroare='Functia ' + RTrim(@cod) + ' apare in ' + (case @tabReferinta when 1 then 'salariati!' when 2 then 'istoric salariati!' else '' end)
		raiserror(@mesajEroare, 16, 1)
	end

	insert into functii (cod_functie, denumire, nivel_de_studii)
	select x.cod, isnull(x.denumire,''), isnull(x.nivel_studii,'')
	from #xmlfunctii x
	where x.ptupdate=0

	-- salvarea detaliilor e tratata doar la importul unei singure functii
	select top 1 @detalii= detalii, @cod=cod from #xmlfunctii
	SET @docDetalii = (SELECT @cod as codfunctie,'functii' as tabel, @detalii for xml raw)
	exec wScriuDetalii  @parXML=@docDetalii

	insert into extinfop (marca, cod_inf, val_inf, data_inf, procent)
	select x.cod, '#CODCOR', x.codcor, '1901-01-01', 0
	from #xmlfunctii x
	where (x.ptupdate=0 or not exists (select * from extinfop where cod_inf='#CODCOR' and marca=x.cod))
	and x.codcor<>''

	update f
	set Cod_functie=isnull(x.cod, f.Cod_functie), Denumire=isnull(x.denumire,f.Denumire), 
	Nivel_de_studii=isnull(x.nivel_studii,f.Nivel_de_studii)
	from functii f, #xmlfunctii x
	where x.ptupdate=1 and f.Cod_functie=x.o_cod

	update e
	set marca=isnull(x.cod, e.Marca), val_inf=isnull(x.codcor,e.Val_inf)
	from extinfop e, #xmlfunctii x
	where x.ptupdate=1 and e.Marca=x.o_cod and e.cod_inf='#CODCOR'

--	Lucian: am mutat partea de mai jos scrisa de Cipri, mai sus in insertul din extinfop cu conditia de OR
/*	
	--inserez in extinfop pentru cazurile in care exista functia in tabela functii dar nu exista corespondent in tabela extinfop
	insert extinfop (Marca,Cod_inf,Val_inf,Data_inf,Procent)
	select x.cod,'#CODCOR',x.numarcor,'',''
	from #xmlfunctii x
	left outer join extinfop e on e.marca=x.cod and e.cod_inf='#CODCOR'
	where x.cod is not null and x.numarcor is not null
	and e.marca is null
*/

--	selectez campurile definite ca proprietati
	select 'DESCRIERE' as codproprietate, descriere as valoare, o_descriere as o_valoare
	into #proprietati
	from #xmlfunctii p where descriere is not null
	union all
	select 'SCOP' as codproprietate, scop as valoare, o_scop as valoare
	from #xmlfunctii p where scop is not null
	union all
	select 'STUDII' as codproprietate, studii as valoare, o_studii as o_valoare
	from #xmlfunctii p where studii is not null
	union all
	select 'EXPERIENTA' as codproprietate, experienta as valoare, o_experienta as o_valoare
	from #xmlfunctii p where experienta is not null
	union all
	select 'DOMENIU' as codproprietate, rtrim(convert(char(1000),id_domeniu)) as valoare, rtrim(convert(char(1000),o_id_domeniu)) as o_valoare
	from #xmlfunctii p where id_domeniu is not null

	declare @input XML
	set @input=(select top 1 'FUNCTII' as '@tip', rtrim(Cod) as '@cod', 
			--formare proprietati de scris
			(select ptupdate as '@update', codproprietate as '@codproprietate', Valoare as '@valoare', o_valoare as '@o_valoare'
			from #proprietati p
			for XML path,type)
		from #xmlfunctii 
		for xml Path,type)
--	de vazut ce se intampla daca nu am de trimis proprietati
--	select @input
	exec wScriuProprietati @sesiune, @input	 
/*
	if @descriere is not null
		exec wScriuProprietati 'FUNCTII', @cod, 'DESCRIERE', @descriere, ''
	if @scop is not null
		exec wScriuProprietati 'FUNCTII', @cod, 'SCOP', @scop, ''
	if @studii is not null
		exec wScriuProprietati 'FUNCTII', @cod, 'STUDII', @studii, ''
	if @experienta is not null
		exec wScriuProprietati 'FUNCTII', @cod, 'EXPERIENTA', @experienta, ''
	if @id_domeniu is not null
		exec wScriuProprietati 'FUNCTII', @cod, 'DOMENIU', @id_domeniu, ''
*/	
	--COMMIT TRAN
end try  
Begin catch
	--ROLLBACK TRAN
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
End catch

IF OBJECT_ID('tempdb..#xmlfunctii') IS NOT NULL
	drop table #xmlfunctii
IF OBJECT_ID('tempdb..#proprietati') IS NOT NULL
	drop table #proprietati
