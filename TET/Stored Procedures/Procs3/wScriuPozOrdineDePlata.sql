
CREATE PROCEDURE wScriuPozOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@utilizator VARCHAR(100), @LMFiltru VARCHAR(20), @idOP INT, @idPozOP INT, @update BIT, @mesaj VARCHAR(400), @cont VARCHAR(20), @data DATETIME, 
		@tipOP VARCHAR(20), @explicatiiOP VARCHAR(2000), @detaliiOP XML, @factura varchar(20), @decont varchar(20),
		@detalii XML, @tipPoz VARCHAR(20), @banca VARCHAR(20), @suma FLOAT, @stare VARCHAR(20), @explicatii VARCHAR(2000), @iban VARCHAR(35), 
		@docPozitii XML, @docJurnalizare XML, @preluare BIT, @sursa VARCHAR(1), @documente xml, 
		@o_explicatii VARCHAR(2000), @o_iban VARCHAR(35), @o_suma FLOAT, @fara_luare_date bit, @cautare varchar(100)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	SELECT @LMFiltru=rtrim(isnull(min(Cod),'')) from LMfiltrare where utilizator=@utilizator /*and cod in (select cod from lm where Nivel=1)*/
	/** Date antet **/
	SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')
	SET @cont = @parXML.value('(/*/@cont)[1]', 'varchar(20)')
	SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
	SET @tipOP = @parXML.value('(/*/@tip)[1]', 'varchar(20)')
	SET @explicatiiOP = @parXML.value('(/*/@explicatii)[1]', 'varchar(2000)')

	/* Date pozitie **/
	SET @idPozOP = @parXML.value('(/*/*/@idPozOP)[1]', 'int')
	SET @suma = @parXML.value('(/*/*/@suma)[1]', 'float')
	SET @o_suma = @parXML.value('(/*/*/@o_suma)[1]', 'float')
	SET @stare = isnull(@parXML.value('(/*/*/@stare)[1]', 'varchar(20)'),'0')
	SET @explicatii = @parXML.value('(/*/*/@explicatii)[1]', 'varchar(2000)')
	SET @factura = @parXML.value('(/*/*/@factura)[1]', 'varchar(20)')
	SET @decont= @parXML.value('(/*/*/@decont)[1]', 'varchar(20)')
	SET @o_explicatii = @parXML.value('(/*/*/@o_explicatii)[1]', 'varchar(2000)')
	SET @o_iban = @parXML.value('(/*/*/@o_iban)[1]', 'varchar(35)')	

	IF @parXML.exist('(/row/detalii/row)[1]') = 1
		SET @detaliiOP = @parXML.query('(/row/detalii/row)[1]')
	IF @parXML.exist('(/*/*/detalii/row)[1]') = 1
		SET @detalii = @parXML.query('(/*/*/detalii/row)[1]')
	IF dbo.f_areLMFiltru(@utilizator)=1 and @detaliiOP.value('(/row/@lm)[1]', 'varchar(9)') is null
	BEGIN
		IF @detaliiOP is null 
			set @detaliiOP='<row />'
		set @detaliiOP.modify ('insert attribute lm {sql:variable("@LMFiltru")} into (/row)[1]')
	END

	/** Alte **/
	SET @update = isnull(@parXML.value('(/*/*/@update)[1]', 'bit'), 0)
	SET @fara_luare_date = isnull(@parXML.value('(/*/@fara_luare_date)[1]', 'bit'), 0)
	SET @cautare = @parXML.value('(/*/@_cautare)[1]', 'varchar(max)')
	/** 
		Este un FLAG care indica daca se apeleaza procedura din operatiile de preluare sau daca se adauga pozitii manual
		Daca FLAG-ul este setat "1" se va jurnaliza faptul ca s-a preluat si de unde....
	**/
	SET @preluare = isnull(@parXML.value('(/*/@preluare)[1]', 'bit'), 0)
	SET @sursa = @parXML.value('(/*/@sursa)[1]', 'varchar(10)')

	IF NOT EXISTS (	SELECT 1 FROM conturi	WHERE cont = @cont	)
		RAISERROR ('Contul contabil introdus este invalid!', 11, 1)

	IF @data IS NULL
		RAISERROR ('Data introdusa este invalida!', 11, 1)

	IF OBJECT_ID('temdb..#setPozitiiOP') IS NOT NULL
		DROP TABLE #setPozitiiOP

	SELECT 
		@idOP idOP, 
		Pozitii.poz.value('@tert', 'varchar(20)') tert, 
		Pozitii.poz.value('@marca', 'varchar(20)') marca, 
		Pozitii.poz.value('@factura', 'varchar(20)') factura, 
		Pozitii.poz.value('@decont', 'varchar(20)') decont, 

		Pozitii.poz.value('@banca', 'varchar(20)') banca, 
		Pozitii.poz.value('@iban', 'varchar(35)') iban, 

		Pozitii.poz.value('@explicatii', 'varchar(2000)') explicatii, 
		Pozitii.poz.value('@suma', 'float') suma, 
		Pozitii.poz.value('@stare', 'varchar(20)') stare, 		
		Pozitii.poz.query('(detalii/row)[1]') detalii
	INTO #setPozitiiOP
	FROM @parXML.nodes('/*/row') Pozitii(poz)


	UPDATE  #setPozitiiOP
		set detalii=null
	where convert(varchar(max),detalii)=''

	
	IF @update = 0
	BEGIN
		IF @idOP IS NULL OR isnull(@idOP,'')=''
		BEGIN
			IF OBJECT_ID('tempdb..#idOP') IS NOT NULL
				DROP TABLE #idOP

			CREATE TABLE #idOP (id INT)

			INSERT INTO OrdineDePlata (tip, data, cont_contabil, explicatii, detalii)
			OUTPUT inserted.idOP
			INTO #idOP(id)
			SELECT @tipOP, @data, @cont, @explicatiiOP, @detaliiOP

			SELECT TOP 1 @idOP = id
			FROM #idOP

			SET @docJurnalizare = (
					SELECT @idOP idOP, 'Operat' AS stare, 'Operare' operatie
					FOR XML raw
					)

			UPDATE #setPozitiiOP
			SET idOP = @idOP
--							select *, @idOP from #setPozitiiOP
--							return
			EXEC wScriuJurnalOrdineDePlata @sesiune = @sesiune, @parXML = @docJurnalizare
		END

		INSERT INTO PozOrdineDePlata (idOP, tert, marca, factura, decont, banca, IBAN,  explicatii, suma, stare, detalii)
		SELECT idOP, tert, marca, factura, decont, banca, IBAN, explicatii, suma, stare, detalii
		FROM #setPozitiiOP
	END
	ELSE
		IF @update = 1
		BEGIN
			IF @idPozOP IS NOT NULL
			BEGIN
				UPDATE PozOrdineDePlata
					SET explicatii = @explicatii, suma= @suma, stare = @stare, detalii = @detalii
				where idPozOp=@idPozOP
			END

			SET @docJurnalizare = (
					SELECT @idOP idOP, 
						'Modificare: '+RTRIM(@o_explicatii)
						+(CASE WHEN @suma<>@o_suma THEN ', suma anterioara: '+RTRIM(CONVERT(varchar(100),@o_suma)) ELSE '' end)
						+(CASE WHEN @iban<>@o_iban THEN ', iban anterior: '+RTRIM(@o_iban) ELSE '' end) as operatie
					FOR XML raw
					)

			EXEC wScriuJurnalOrdineDePlata @sesiune = @sesiune, @parXML = @docJurnalizare
		END

	IF @preluare = 1
	BEGIN
		SET @docJurnalizare = (
				SELECT @idOP idOP, 'Preluare din ' + (CASE @sursa WHEN 'D' THEN 'deconturi' WHEN 'F' THEN 'facturi  ' 
					WHEN 'S' THEN 'salarii  '	END) AS operatie
				FOR XML raw
				)

		EXEC wScriuJurnalOrdineDePlata @sesiune = @sesiune, @parXML = @docJurnalizare
	END

	SET @docPozitii = (
			SELECT @idOP idOP, @cautare _cautare
			FOR XML raw
			)
	
	if @fara_luare_date=0
	BEGIN
		IF @tipOP='FA'
			EXEC wIaPozOrdineDeplataFacturi @sesiune = @sesiune, @parXML = @docPozitii
		IF @tipOP='SA'
			EXEC wIaPozOrdineDeplataSalarii @sesiune = @sesiune, @parXML = @docPozitii
		IF @tipOP='CS'
			EXEC wIaPozOrdineDePlataContributii @sesiune = @sesiune, @parXML = @docPozitii
	END
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPozOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
