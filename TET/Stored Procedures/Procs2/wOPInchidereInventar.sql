--***
CREATE PROCEDURE wOPInchidereInventar @sesiune VARCHAR(50), @parXML XML
AS
if OBJECT_ID('wOPInchidereInventarSP') is not null
begin
	exec wOPInchidereInventarSP @sesiune=@sesiune, @parXML=@parXML
	return
end
BEGIN TRY
	DECLARE @data DATETIME, @gestiune VARCHAR(20), @tipdoc VARCHAR(4), @contcor VARCHAR(20), @tipCor VARCHAR(1), @gestprim VARCHAR(
			20), @mesaj VARCHAR(400), @semn INT, @nrdoc VARCHAR(20), @tip2 VARCHAR(2), @pX XML, @pX2 XML,@grupa varchar(20),
			@idInventar int, @locatie varchar(20),@subunitate varchar(20)

	exec luare_date_par 'GE','SUBPRO',0,0,@subunitate OUTPUT
	SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
	SET @gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)')
	SET @grupa= @parXML.value('(/*/@grupa)[1]', 'varchar(20)')  
	SET @tipdoc = @parXML.value('(/*/@tipuriDoc)[1]', 'varchar(4)')
	SET @tipCor = @parXML.value('(/*/@tipuriCor)[1]', 'varchar(1)')
	SET @contcor = @parXML.value('(/*/@contcorespondent)[1]', 'varchar(20)')
	SET @gestprim = @parXML.value('(/*/@gestiuneprimitoare)[1]', 'varchar(20)')
	set @locatie=@parXML.value('(/*/@locatie)[1]', 'varchar(20)')

	IF @tipdoc IN ('AI', 'AE', 'CM', 'AIAE')
		AND isnull(@contcor, '') = ''
		RAISERROR ('La acest tip de document este necesara completarea contului corespondent!', 11, 1)

	IF @tipdoc IN ('TE','PF')
		AND isnull(@gestprim, '') = ''
		RAISERROR ('La acest tip de document este necesara completarea gestiunii primitoare!', 11, 1)

	IF @tipdoc = 'AIAE'
		AND @tipcor <> 'T'
		RAISERROR ('Pentru documente de tipul Alte Intrari/Iesiri selectati "Toate" corectiile!', 11, 1)

	--identificare inventar 
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AntetInventar]') AND type in (N'U'))
	begin
		SELECT TOP 1 @idInventar = idInventar
			FROM AntetInventar
			WHERE data = @data
				AND gestiune = @gestiune
				and (grupa=@grupa or isnull(@grupa,'')='')--daca sunt inventare deschise la nivel de grupa
	end
	
	IF @tipdoc = 'AIAE'
	BEGIN
		SET @tipdoc = 'AI'
		SET @tipCor = 'P'
		SET @tip2 = 'AE'
	END

	declare @parXML2 xml
	select @parXML2=(select @data data, @gestiune gestiune,@grupa grupa, @locatie locatie,1 as faradocumentcorectie for xml raw)
	
	CREATE TABLE #comparativa (
		cod VARCHAR(20), stoc_scriptic FLOAT, stoc_faptic FLOAT, pret FLOAT, plusinv FLOAT, minusinv FLOAT, valplusinv FLOAT, 
		valminusinv FLOAT,pretstoc float,pretam float
		)

	INSERT INTO #comparativa
	EXEC wGenerareInventarComparativa @parXML=@parXML2

	--In cazul in care generam intrari inversam semnul.
	IF @tipdoc IN ('AI','AF')
		SET @semn = 1
	ELSE
		SET @semn = - 1
	
	declare @detalii xml
	set @detalii='<row idInventar="'+convert(varchar,@idInventar)+'"/>'
	
	SET @nrdoc = 'INV' + convert(varchar,ISNULL(@idInventar,@gestiune))
	SET @pX = (
			SELECT @tipdoc AS '@tip', @nrdoc AS '@numar', @data AS '@data', @gestiune AS '@gestiune', (CASE WHEN @tipdoc IN ('AI', 'AE', 'CM') THEN @contcor END
					) AS '@contcorespondent', '9' AS '@stare', (CASE @tipdoc WHEN 'TE' THEN @gestprim WHEN 'PF' THEN @gestprim END) AS 
				'@gestprim',@locatie '@locatie', @detalii as detalii,
					(SELECT rtrim(cod) AS '@cod', convert(DECIMAL(12, 3), @semn * (plusinv - minusinv
								)) AS '@cantitate', convert(DECIMAL(15, 2), pret) AS '@pamanunt',
								convert(decimal(15,2),pretstoc) as '@pstoc' , @detalii as detalii
					FROM #comparativa
					WHERE (
							(
								@tipCor = 'T'
								AND abs(plusinv - minusinv) > 0.01
								)
							OR (
								@tipCor = 'P'
								AND plusinv > 0.01
								)
							OR (
								@tipCor = 'M'
								AND minusinv > 0.01
								)
							)
					FOR XML path, Type
					)
			FOR XML path, type
			)
	delete from pozdoc where subunitate=@subunitate and tip=@tipdoc and numar=@nrdoc and data=@data
	EXEC wScriuPozdoc @sesiune = @sesiune, @parXML = @pX

	IF @tip2 IS NOT NULL
	BEGIN
		SET @semn = - 1
		SET @pX2 = (
				SELECT @tip2 AS '@tip', @nrdoc AS '@numar', @data AS '@data', @gestiune AS '@gestiune', @contcor AS '@contcorespondent'
					, '9' AS '@stare',@locatie '@locatie', @detalii as detalii,
					(SELECT rtrim(cod) AS '@cod', convert(DECIMAL(12, 3), @semn * (plusinv - minusinv
									)) AS '@cantitate', convert(DECIMAL(15, 2), pret) AS '@pamanunt', @detalii as detalii
						FROM #comparativa
						WHERE minusinv > 0.01
						FOR XML path, Type
						)
				FOR XML path, type
				)

		delete from pozdoc where subunitate=@subunitate and tip=@tip2 and numar=@nrdoc and data=@data
		EXEC wScriuPozdoc @sesiune = @sesiune, @parXML = @pX2
	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPInchidereInventar)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
