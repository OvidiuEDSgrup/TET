CREATE PROCEDURE yso_wOPCompletareDetaliiCorectii @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @iDoc int, @tert VARCHAR(20), @mesaj VARCHAR(400), @dataJos DATETIME, @dataSus DATETIME,
		@tip VARCHAR(2), @utilizator varchar(50), @suma float, @data datetime, @valuta varchar(3),
		@dentert varchar(200), @numar varchar(20), @cont varchar(13), @curs float, @sub varchar(9),
		@soldTert float, @lm varchar(13), @factura varchar(20), @gestiune varchar(13), @cod varchar(20), @flm int
		,@docVanzareComisionat varchar(40), @tipDoc varchar(2), @nrDoc varchar(8), @dataDoc datetime

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati

	declare @idpozadoc int
	set @idpozadoc=@parXML.value('(/*/@idpozadoc)[1]', 'int')
	
	if @idpozadoc is null
	begin
		raiserror( 'Operatie de modificare date pozitie nepermisa pe antetul documentului, selectati o pozitie din document!',11,1)
	end  
	
	SELECT
		@tip = isnull(@parXML.value('(/*/@tip)[1]', 'varchar(2)'),''),
		@tert = isnull(@parXML.value('(//@tert)[1]', 'varchar(20)'),''),
		@numar = isnull(@parXML.value('(//@numar)[1]', 'varchar(20)'),''),
		@factura = isnull(@parXML.value('(//@factura)[1]', 'varchar(20)'),isnull(@parXML.value('(/*/*/@factura)[1]', 'varchar(20)'),'')),
		@docVanzareComisionat = isnull(@parXML.value('(//@docVanzareComisionat)[1]', 'varchar(40)')
			,isnull(@parXML.value('(/*/*/*/@docVanzareComisionat)[1]', 'varchar(40)'),'')),
		@valuta = isnull(isnull(@parXML.value('(//@valuta)[1]', 'varchar(3)'),@parXML.value('(/*/*/@valuta)[1]', 'varchar(3)')),''),
		@lm = isnull(@parXML.value('(/*/*/@lm)[1]', 'varchar(13)'),isnull(@parXML.value('(/*/@lm)[1]', 'varchar(13)'),'')),
		@cod = isnull(@parXML.value('(/*/*/@cod)[1]', 'varchar(20)'),''),
		@gestiune = isnull(@parXML.value('(//@gestiune)[1]', 'varchar(13)'),''),
		@suma = isnull(@parXML.value('(//@suma)[1]', 'float'),'0'),
		@curs = isnull(isnull(@parXML.value('(//@curs)[1]', 'float'),@parXML.value('(/*/*/@curs)[1]', 'float')),0) ,
		@data = isnull(@parXML.value('(//@data)[1]', 'datetime'),''),
		@dataJos = ISNULL(@parXML.value('(//@datajos)[1]', 'datetime'),'1901-01-01'),
		@dataSus = ISNULL(@parXML.value('(//@datasus)[1]', 'datetime'),'2901-01-01')
		
	select @tipDoc=LEFT(@docVanzareComisionat,2), @nrDoc=SUBSTRING(@docVanzareComisionat,3,8), @dataDoc=CONVERT(date,RIGHT(@docVanzareComisionat,10))
	
	--if ISNULL(@valuta,'')<>'' and ISNULL(@curs,0)=0
	--	raiserror('Daca ati selectat o valuta, trebuie sa introduceti si cursul valutar!',11,1)

	--if ISNULL(@tert,'')=''
	--	raiserror('Tert necompletat!',11,1)
		
	IF @docVanzareComisionat<>''
		insert yso_LegComisionVanzari (subDoc,tipDoc,dataDoc,nrDoc,idPozDoc)
		select @sub, @tipDoc, @dataDoc, @nrDoc, @idpozadoc

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlDoc') IS NOT NULL
		DROP TABLE #xmlDoc
	
	SELECT sub as sub,tip as tip,data as data,numar as numar, subtip as subtip
		,furnizor, factFurniz, beneficiar, factBenef, convert(decimal(17,2),suma) as suma, valuta as valuta, curs as curs
		,selectat as selectat, factnoua as factnoua, lm, isnull(sumatva,0) as val_tva, space(20) as cont_fact, isnull(cotatva,0) as cotatva
	INTO #xmlDoc
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(	
		sub varchar(9) '@sub'
		,tip varchar(2) '@tip'
		,numar varchar(8) '@numar'
		,data varchar(10) '@data'
		,furnizor varchar(20) '@furnizor'
		,factFurniz varchar(20) '@factFurniz'
		,beneficiar varchar(20) '@beneficiar'
		,factBenef varchar(20) '@factBenef'
		,suma float '@suma' 
		,subtip varchar(2) '@subtip'
		,valuta varchar(3) '@valuta'
		,curs float '@curs'
		,selectat int '@selectat'
		,factnoua int '@factnoua'
		,lm varchar(13) '@lm',
		cotatva float '@cotatva',
		sumatva float '@sumatva'
	)
	
	EXEC sp_xml_removedocument @iDoc 	
--select convert(datetime,x.data,101),*
--from #xmlDoc x
/*
select * --*/ delete f
	from yso_LegComisionVanzari f join #xmlDoc x on x.sub=f.subDoc and x.tip=f.tipDoc 
		and convert(datetime,x.data,101)=f.dataDoc and x.numar=f.nrDoc
	where f.idPozDoc=@idpozadoc and x.selectat=1

	DECLARE @dateInitializare XML
	SET @dateInitializare='<row idpozdoc="'+ltrim(str(@idpozadoc))+'" />'

	set @parXML.modify('delete /*/*')
	set @parXML=dbo.fInlocuireDenumireElementXML(@parXML,'row')
	set @parXML.modify('insert sql:variable("@dateInitializare") as last into (/row)[1]')

	SELECT 'Comisionare documente vanzari' nume, 'DO' codmeniu, 'D' tipmacheta, 'RS' tip,'CV' subtip,'O' fel,
		(SELECT @parXML ) dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')	

END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wOPCompletareDetaliiCorectii)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH