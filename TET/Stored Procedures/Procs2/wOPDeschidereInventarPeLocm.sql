
CREATE PROCEDURE wOPDeschidereInventarPeLocm @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE @deschidereXML xml, @populareXML xml, @idInventar int, @tip varchar(2),
		@data datetime, @lm varchar(50), @tipinventar varchar(2), @nrPozitii int,@codGestiune varchar(20)
	DECLARE @lista table(cod varchar(50))

	SELECT @data = @parXML.value('(/parametri/@data)[1]', 'datetime'),
		@tip = @parXML.value('(/parametri/@tip)[1]', 'varchar(2)'),
		@lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(50)'), ''),
		@tipinventar = ISNULL(@parXML.value('(/parametri/@tipinventar)[1]', 'varchar(2)'),(CASE WHEN @tip = 'ID' THEN 'G' ELSE 'M' END))

	IF @lm = ''
		RAISERROR('Selectati un loc de munca!', 16, 1)

	/** Identificare gestiuni/marci care au locul de munca selectat (ID - gestiune; altfel - marca) */
	IF @tip = 'ID'
	BEGIN
		INSERT INTO @lista(cod)
		SELECT RTRIM(g.Cod_gestiune)
		FROM gestiuni g
		WHERE g.detalii.value('(/row/@lm)[1]', 'varchar(50)') like rtrim(@lm)+'%'
	END
	ELSE
	BEGIN
		INSERT INTO @lista(cod)
		SELECT RTRIM(p.Marca)
		FROM personal p
		WHERE p.Loc_de_munca like rtrim(@lm)+'%'
	END


	set @codGestiune=null
	select top 1 @codGestiune=cod from @lista

	WHILE @codGestiune is not null
	BEGIN
		/** Apelare operatie de deschidere inventar */
		SET @deschidereXML =
		(
			SELECT @data AS data, @codGestiune AS gestiune, @tip AS tip, @tipinventar AS tipinventar
			FOR XML RAW
		)
		EXEC wOPDeschidereInventar @sesiune = @sesiune, @parXML = @deschidereXML

		/** Output idInventar pentru trimitere la populare inventar */
		SELECT @idInventar = IDENT_CURRENT('AntetInventar')

		/** Apelare operatie de populare inventar */
		SET @populareXML =
		(
			SELECT @data AS data, @codGestiune AS gestiune, @tipinventar AS tipinventar, @idInventar AS idInventar,
				1 AS fara_mesaje --> trimitem fara_mesaje ca sa nu ne afiseze textMesaj pentru fiecare populare.
			FOR XML RAW
		)
		EXEC wOPPopulareInventar @sesiune = @sesiune, @parXML = @populareXML

		/** Daca dupa populare nu se adauga nicio pozitie, se va sterge acel inventar. */
		SELECT @nrPozitii = COUNT(p.idPozInventar) FROM PozInventar p WHERE p.idInventar = @idInventar
		IF @nrPozitii = 0
		BEGIN
			DELETE FROM AntetInventar WHERE idInventar = @idInventar
		END

		delete from @lista where cod=@codGestiune
		set @codGestiune=null
		select top 1 @codGestiune=cod from @lista
	END

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
