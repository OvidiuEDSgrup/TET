
CREATE PROCEDURE wScriuNomenclatorImpl @sesiune varchar(50), @parXML xml
AS
BEGIN
	
	DECLARE @grupa varchar(13), @cod varchar(20), @denumire varchar(200), @cont varchar(40),
		@um varchar(3), @pret_stocn float, @pretvanznom float,@pretamnom float, @cotatva float, @detalii xml,
		@stocmin decimal(12,3), @stocmax decimal(12,3), @greutate float, @um_1 varchar(3),
		@nomenclXML xml, @antetXML xml, @tip varchar(20), @denumireGrupa varchar(200),
		@grupa_parinte varchar(13), @cont_grupa varchar(40), @grupaXML xml, @update bit,
		@preturi xml

	SELECT
		/** Date grupa */
		@grupa = @parXML.value('(/row/@grupa)[1]', 'varchar(13)'),
		@tip = @parXML.value('(/row/@tip)[1]', 'varchar(20)'),
		@denumireGrupa = @parXML.value('(/row/@denumire)[1]', 'varchar(200)'),
		@grupa_parinte = @parXML.value('(/row/@grupa_parinte)[1]', 'varchar(13)'),
		@cont_grupa = @parXML.value('(/row/detalii/row/@cont)[1]', 'varchar(40)'),

		/** Date nomenclator */
		@cod = @parXML.value('(/row/row/@cod)[1]', 'varchar(20)'),
		@denumire = @parXML.value('(/row/row/@denumire)[1]', 'varchar(200)'),
		@cont = @parXML.value('(/row/row/@cont)[1]', 'varchar(40)'),
		@um = @parXML.value('(/row/row/@um)[1]', 'varchar(3)'),
		@pret_stocn = @parXML.value('(/row/row/@pret_stocn)[1]', 'float'),
		@pretvanznom = @parXML.value('(/row/row/@pretvanznom)[1]', 'float'),
		@pretamnom = @parXML.value('(/row/row/@pretamnom)[1]', 'float'),
		@cotatva = @parXML.value('(/row/row/@cotatva)[1]', 'float'),
		@stocmin = @parXML.value('(/row/row/@stocmin)[1]', 'decimal(12,3)'),
		@stocmax = @parXML.value('(/row/row/@stocmax)[1]', 'decimal(12,3)'),
		@greutate = @parXML.value('(/row/row/@greutate)[1]', 'float'),
		@um_1 = @parXML.value('(/row/row/@UM_1)[1]', 'varchar(3)'),
		@detalii = @parXML.query('/row/row/detalii/row'),
		@update = ISNULL(@parXML.value('(/row/row/@update)[1]', 'bit'), 0)
	
	/** Verificam daca grupa exista */
	IF NOT EXISTS (SELECT 1 FROM grupe WHERE grupa = @grupa)
	BEGIN
		SET @grupaXML =
		(
			SELECT @grupa AS grupa, @tip AS tip, @denumireGrupa AS denumire,
				@grupa_parinte AS grupa_parinte, (SELECT @cont_grupa AS cont FOR XML RAW, TYPE) AS detalii
			FOR XML RAW
		)
		EXEC wScriuGrupe @sesiune = @sesiune, @parXML = @grupaXML
	END

	/** Trimitem la wScriuNomenclator cu /row/...
		Din macheta de tip document "Date implementare" se trimite /row/row/...
		ceea ce ar face sa nu fie citit codul produsului. */
	SET @nomenclXML =
	(
		SELECT @grupa AS grupa, @cod AS cod, @denumire AS denumire, @cont AS cont,
			@um AS um, @pret_stocn AS pret_stocn, @pretvanznom AS pretvanznom,
			@cotatva AS cotatva, @stocmin AS stocmin, @stocmax AS stocmax,
			@greutate AS greutate, @um_1 AS um_1, @update AS [update], @detalii AS detalii
		FOR XML RAW
	)
	EXEC wScriuNomenclator @sesiune = @sesiune, @parXML = @nomenclXML

	/** Daca nu se specifica codul, nu se scrie pretul de vanzare in tabela preturi,
		decat la modificare. */
	IF ISNULL(@pretamnom, 0) <> 0
	BEGIN
		IF ISNULL(@cod, '') <> ''
		BEGIN
			SET @preturi =
			(
				SELECT @cod AS cod, (SELECT @update AS [update], '1' AS catpret,
					'1' AS tippret, CONVERT(decimal(12,2), @pretamnom) AS pret_cu_amanuntul,
					CONVERT(varchar(10), GETDATE(), 101) AS data_inferioara FOR XML RAW, TYPE)
				FOR XML RAW
			)
			EXEC wScriuPreturiNomenclator @sesiune = @sesiune, @parXML = @preturi
		END
	END

	/** Pastram antetul */
	SET @antetXML = (SELECT @grupa AS grupa FOR XML RAW)
	EXEC wIaNomenclatorImpl @sesiune = @sesiune, @parXML = @antetXML
END
