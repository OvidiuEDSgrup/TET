/***--
Procedura stocata citeste pozitiile inventarului.
	
param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele.

--***/
CREATE PROCEDURE wmIaWPozInv @sesiune VARCHAR(50), @parXML XML
AS
-- apelare procedura specifica daca aceasta exista.
IF EXISTS (SELECT 1 FROM sysobjects WHERE [type] = 'P' AND [name] = 'wmIaWPozInvSP')
BEGIN
	DECLARE @returnValue INT
	EXEC @returnValue = wmIaWPozInvSP @sesiune, @parXML
	RETURN @returnValue
END

DECLARE @userASiS VARCHAR(50), @mesaj VARCHAR(100), @raspuns VARCHAR(max), @actiune VARCHAR(20), @idInventar INT, @searchText 
	VARCHAR(100), @stareInventar INT, @codcitit VARCHAR(100), @codScanat VARCHAR(100)

BEGIN TRY
	/*Validare utilizator */
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

	/*Citeste variabile din parametrii */
	SET @idInventar = @parXML.value('(/*/@idInventar)[1]', 'int')
	SET @stareInventar = @parXML.value('(/*/@stareInventar)[1]', 'int')
	SET @searchText = '%' + ISNULL(REPLACE(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ' ', '%'), '') + '%'

	/** Daca inventarul este blocat nu se poate opera de pe mobile **/
	IF @stareInventar <> 0
		RAISERROR ('Inventarul selectat este in starea: "blocat temporar" ! Nu se pot opera articole in inventar', 11, 1
				)

	/*Citire cod bare */
	-- verific daca s-a scanat in searchText un cod de bare
	SELECT @codcitit = rtrim(@parXML.value('(/*/@searchText)[1]', 'varchar(100)')), @codcitit = REPLACE(@codcitit, 'CipherLab', 
			'')
	IF len(isnull(@codcitit, '')) > 0
	BEGIN
		--il cautam in tabela de coduri de bare
		SELECT @codScanat = rtrim(cb.Cod_produs)
		FROM codbare cb
		WHERE cb.Cod_de_bare = @codcitit

		IF @codScanat IS NOT NULL --inseamna ca am gasit cod scanat
		BEGIN
			declare @xml xml
			select @xml = 
				(select 
					p.idPozInventar,
					p.idInventar,
					rtrim(@codScanat) as cod,
					'refresh' as actiune
				from PozInventar p
				where idInventar=@idInventar and cod=@codScanat
				for xml raw)
			exec wmScriuWPozInv @sesiune=@sesiune, @parXML=@xml
			set @parXML.modify('delete (/row/@searchText)[1]')
			exec wmIaWPozInv @sesiune=@sesiune, @parXML=@parXML
			select '1' clearSearch for xml raw, root('Mesaje')
			return
			/*SET @actiune = 'autoSelect'
			SET @searchText = '%'*/
		END
	END

	/*Raspunsul de la server */
	SET @raspuns = '<Date>' + CHAR(13);

	IF (@codScanat IS NULL)
		IF (@searchText = '%%')
		BEGIN
			/*Pozitii din Inventar*/
			SET @raspuns = @raspuns + isnull((
						SELECT TOP 25 rtrim(pi.cod) AS cod, rtrim(pi.cod)+'-'+RTRIM(n.Denumire) AS denumire, ltrim(isnull(str(pi.stoc_faptic, 10, 2), 
									'0')) AS info, 1 AS _upsideDown, pi.idPozInventar idPozInventar,
									case when pi.detalii.value('(/row/@stare)[1]','varchar(20)')='scanat' then '0x990033' else '0x000000' end as culoare,
									case when pi.detalii.value('(/row/@stare)[1]','varchar(20)')='scanat' then 1 else 0 end as ordine
						FROM PozInventar pi
						LEFT JOIN nomencl n
							ON n.Cod = pi.cod
						WHERE pi.idInventar = @idInventar
						order by 7
						FOR XML raw
						), '') + CHAR(13);
		END
		ELSE
		BEGIN
			/*Pozitii din nomenclator selectate dupa denumire*/
			SET @raspuns = @raspuns + ISNULL((
						SELECT TOP 25 rtrim(n.Cod) AS cod, rtrim(n.Cod)+'-'+RTRIM(n.Denumire) AS denumire, ltrim(isnull(str(pozInv.nrProduse, 10, 2)
									, '0')) AS info, pozInv.idPozInventar idPozInventar, 1 AS _upsideDown,
									case when pozInv.detalii.value('(/row/@stare)[1]','varchar(20)')='scanat' then '0x990033' else '0x000000' end as culoare,
									case when pozInv.detalii.value('(/row/@stare)[1]','varchar(20)')='scanat' then 1 else 0 end as ordine
						FROM nomencl n
						LEFT JOIN (
							SELECT pi.idPozInventar idPozInventar, pi.cod cod, pi.stoc_faptic nrProduse, pi.detalii
							FROM PozInventar pi
							WHERE pi.idInventar = @idInventar
							) pozInv
							ON n.Cod = pozInv.cod
						WHERE (n.cod like @searchText+'%' or  n.Denumire LIKE @searchText)
						order by 7
						FOR XML raw
						), '') + CHAR(13);
		END
	ELSE
	BEGIN
		/*Pozitia scanata adusa din nomenclator*/
		SET @raspuns = @raspuns + ISNULL((
					SELECT TOP 25 rtrim(n.Cod) AS cod, rtrim(n.Cod)+'-'+RTRIM(n.Denumire) AS denumire, ltrim(isnull(str(pozInv.nrProduse, 10, 2), '0'
							)) AS info, pozInv.idPozInventar idPozInventar, @codcitit codBare, 1 AS _upsideDown,
							case when pozInv.detalii.value('(/row/@stare)[1]','varchar(20)')='scanat' then '0x990033' else '0x000000' end as culoare,
							case when pozInv.detalii.value('(/row/@stare)[1]','varchar(20)')='scanat' then 1 else 0 end as ordine
					FROM nomencl n
					LEFT JOIN (
						SELECT pi.idPozInventar idPozInventar, pi.cod cod, pi.stoc_faptic nrProduse,pi.detalii
						FROM PozInventar pi
						WHERE pi.idInventar = @idInventar
						) pozInv
						ON n.Cod = pozInv.cod
					WHERE n.Cod = @codScanat
					order by 8
					FOR XML raw
					), '') + CHAR(13);
	END

	SET @raspuns = @raspuns + '</Date>';
	
	SELECT CONVERT(XML, @raspuns);

	SELECT 'wmScriuWPozInv' AS detalii, 1 AS areSearch, 1 AS focusSearch, 1 AS _toateAtr, @actiune AS actiune, 'D' AS _tipdetalii, (CASE WHEN ISNULL(@codScanat, '') = '' THEN NULL ELSE 1 END
			) AS _clearSearch, dbo.f_wmIaForm('WI') AS form
	FOR XML raw, root('Mesaje');
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wmIaWPozInv)'
END CATCH

IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 11, 1)
