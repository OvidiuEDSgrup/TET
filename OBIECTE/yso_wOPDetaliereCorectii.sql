IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'yso_wOPDetaliereCorectii')
	DROP PROCEDURE yso_wOPDetaliereCorectii
GO
CREATE PROCEDURE yso_wOPDetaliereCorectii @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @iDoc int, @tert VARCHAR(20), @mesaj VARCHAR(400), @dataJos DATETIME, @dataSus DATETIME,
		@tip VARCHAR(2), @utilizator varchar(50), @suma float, @data datetime, @valuta varchar(3),
		@dentert varchar(200), @numar varchar(20), @cont varchar(13), @curs float, @sub varchar(9),
		@soldTert float, @lm varchar(13), @factura varchar(20), @gestiune varchar(13), @cod varchar(20), @flm int,
		@docVanzareComisionat varchar(40), @tipDoc varchar(2), @nrDoc varchar(8), @dataDoc datetime,
		@cantitate float, @pret float, @pret_valuta float
		
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
		@cod = isnull(@parXML.value('(/*/@cod)[1]', 'varchar(20)'),''),
		@cantitate = isnull(@parXML.value('(/*/@cantitate)[1]', 'float'),0),
		@pret = ISNULL(@parXML.value('(/*/@pret)[1]','float'),0),
		@pret_valuta = ISNULL(@parXML.value('(/*/@pret_valuta)[1]','float'),0),
		@tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(20)'),'')
		
	select @tipDoc=LEFT(@docVanzareComisionat,2), @nrDoc=SUBSTRING(@docVanzareComisionat,3,8), @dataDoc=CONVERT(date,RIGHT(@docVanzareComisionat,10))
		
	IF @cod<>''
		insert into yso_Articole_corectii (idPozADoc, subunit, tert, cod_articol, cantitate, pret, pret_valuta)
		select @idpozadoc, @sub, @tert, @cod, @cantitate, @pret, @pret_valuta

	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlDoc') IS NOT NULL
		DROP TABLE #xmlDoc
	
	SELECT cod_articol as cod_articol, selectat as selectat
	INTO #xmlDoc
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(	
		cod_articol varchar(20) '@cod_articol'
		,selectat int '@selectat'
	)
	
	EXEC sp_xml_removedocument @iDoc 	

/*
select * --*/ delete f
	from yso_Articole_corectii f join #xmlDoc x on x.cod_articol = f.cod_articol 
	where f.idPozADoc=@idpozadoc and x.selectat=1

	DECLARE @dateInitializare XML
	SET @dateInitializare='<row idpozadoc="'+ltrim(str(@idpozadoc))+'" />'

	set @parXML.modify('delete /*/*')
	set @parXML=dbo.fInlocuireDenumireElementXML(@parXML,'row')
	set @parXML.modify('insert sql:variable("@dateInitializare") as last into (/row)[1]')

	SELECT 'Detaliere corectii ' nume, 'AD' codmeniu, 'D' tipmacheta, 'FF' tip,'DC' subtip,'O' fel,
		(SELECT @parXML ) dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')	

END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wOPDetaliereCorectii)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH