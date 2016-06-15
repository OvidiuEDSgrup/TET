--***
Create 
procedure wScriuBenret @sesiune varchar(50), @parXML xml
as 

Declare @iDoc int, @cod varchar(20), @referinta int, @tabReferinta int, @eroare xml, 
@mesaj varchar(254), @mesajEroare varchar(254)

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlbenret') IS NOT NULL
	drop table #xmlbenret

begin try  
	select isnull(ptupdate, 0) as ptupdate, cod, isnull(cod_vechi, cod) as cod_vechi, 
		denumire, tipret, obiectret, codfiscal, bazaprocent, banca, contbanca, 
		contdebitor, contcreditor, analiticmarca
	into #xmlbenret
	from OPENXML(@iDoc, '/row')
	WITH
	(
		ptupdate int '@update', 
		cod varchar(13) '@cod',
		cod_vechi varchar(13) '@o_cod',
		denumire varchar(30) '@denumire',
		tipret varchar(1) '@tipret',
		obiectret varchar(30) '@obiectret',
		codfiscal varchar(9) '@codfiscal',
		bazaprocent varchar(1) '@bazaprocent',
		banca varchar(30) '@banca',
		contbanca varchar(30) '@contbanca',
		contdebitor varchar(13) '@contdebitor',
		contcreditor varchar(13) '@contcreditor',
		analiticmarca int '@analiticmarca'
	)
	exec sp_xml_removedocument @iDoc 
	while exists (select 1 from #xmlbenret x where x.ptupdate=0 and isnull(x.cod, '')='')
	begin
		declare @UltCod varchar(13)
		if (@cod is null)  	
			exec wmaxcod 'Cod_beneficiar','benret',@UltCod output
		update top (1) x
		set Cod_beneficiar=RTrim(LTrim(convert(char(9), @UltCod)))
		from #xmlbenret x
		where x.ptupdate=0 and isnull(x.Cod, '')=''

	End

	if exists (select 1 from #xmlbenret where isnull(cod, '')='')
		raiserror('Cod beneficiar necompletat!', 16, 1)
	if exists (select 1 from #xmlbenret where isnull(denumire, '')='')
		raiserror('Denumire beneficiar necompletata!', 16, 1)
	if exists (select 1 from #xmlbenret where isnull(tipret, '')='')
		raiserror('Tip retinere necompletat!', 16, 1)
	select @cod=x.cod
	from #xmlbenret x, benret b 
	where b.Cod_beneficiar=x.cod and (x.ptupdate=0 or x.ptupdate=1 and x.cod<>x.cod_vechi)
	if @cod is not null
	begin
		set @mesajEroare='Beneficiar retinere ' + RTrim(@cod) + ' este deja introdus!'
		raiserror(@mesajEroare, 16, 1)
	end

	select @referinta=dbo.wfRefBeneficiariRetineri(x.cod_vechi), 
		@cod=(case when @referinta>0 and @cod is null then x.cod_vechi else @cod end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlbenret x
	where x.ptupdate=1 and x.cod<>x.cod_vechi
	if @cod is not null
	begin
		set @mesajEroare='Beneficiarul ' + RTrim(@cod) + ' apare in ' + (case @tabReferinta when 1 then 'retineri pe salariati!' else '' end)
		raiserror(@mesajEroare, 16, 1)
	end

	insert into benret (Cod_beneficiar, Tip_retinere, Denumire_beneficiar, Obiect_retinere, Cod_fiscal, Banca, Cont_banca, Permane, Cont_debitor, Cont_creditor, Analitic_marca)
	select x.cod, isnull(x.tipret,''), isnull(x.denumire,''), isnull(x.obiectret,''),
	isnull(isnull(x.codfiscal,'')+replicate(' ',9-len(isnull(x.codfiscal,'')))+x.bazaprocent,''),
	isnull(x.banca,''), isnull(x.contbanca,''), 0, isnull(x.contdebitor,''), isnull(x.contcreditor,''), 
	isnull(x.analiticmarca,0)
	from #xmlbenret x
	where x.ptupdate=0

	update b
	set Cod_beneficiar=isnull(x.cod, b.Cod_beneficiar), tip_retinere=isnull(x.tipret,b.tip_retinere), 
	Denumire_beneficiar=isnull(x.denumire,b.Denumire_beneficiar), Obiect_retinere=isnull(x.obiectret,b.Obiect_retinere), 
	Cod_fiscal=isnull(x.codfiscal+replicate(' ',9-len(x.codfiscal))+x.bazaprocent,b.Cod_fiscal), 
	Banca=isnull(x.banca,b.Banca), Cont_banca=isnull(x.contbanca,b.Cont_banca), 
	Cont_debitor=isnull(x.contdebitor,b.Cont_debitor), Cont_creditor=isnull(x.contcreditor,b.Cont_creditor),
	Analitic_marca=isnull(x.analiticmarca,b.Analitic_marca)
	from benret b, #xmlbenret x
	where x.ptupdate=1 and b.Cod_beneficiar=x.cod_vechi
end try  
begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
IF OBJECT_ID('tempdb..#xmlbenret') IS NOT NULL
	drop table #xmlbenret

