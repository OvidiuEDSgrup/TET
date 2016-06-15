
--***
CREATE PROCEDURE [wScriuPozInventar] @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@gestiune VARCHAR(20), @data DATETIME, @cod VARCHAR(20), @stoc_faptic FLOAT, @utilizator VARCHAR(20), 
		@idInventar INT, @idPozInventar INT, @update BIT, @mesaj VARCHAR(500),@barcod varchar(20),@grupa varchar(13), @detalii XML, @cautare varchar(500)

	select @idInventar = @parXML.value('(/*/@idInventar)[1]', 'int'),
		@idPozInventar = @parXML.value('(/*/*/@idPozInventar)[1]', 'int'),
		@gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),
		@grupa = @parXML.value('(/*/@grupa)[1]', 'varchar(13)'),
		@data = @parXML.value('(/*/@data)[1]', 'datetime'),
		@update = isnull(@parXML.value('(/*/*/@update)[1]', 'bit'), 0),		
		@cod = @parXML.value('(/*/*/@cod)[1]', 'varchar(20)'),
		@barcod = @parXML.value('(/*/*/@barcod)[1]', 'varchar(20)'),
		@stoc_faptic = @parXML.value('(/*/*/@stoc_faptic)[1]', 'float'),
		@cautare = @parXML.value('(/*/@_cautare)[1]', 'varchar(100)')

		if @parXML.exist('(/*/*/detalii)[1]')=1
			SET @detalii = @parXML.query('(/*/*/detalii/row)[1]')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	if isnull(@barcod,'')!=''
	begin
		set @cod=null

		select top 1 @cod=cod_produs
		from codbare where cod_de_bare=@barcod

		if @cod is null
			RAISERROR ('Cod de bare nerecunoscut in aplicatie!', 11, 1)
			
	end
	if not exists(select 1 from nomencl where cod=@cod)
			RAISERROR ('Codul produsului nu a fost gasit in nomenclator!', 11, 1)
	
	if not exists(select 1 from nomencl where cod=@cod and grupa=@grupa) and ISNULL(@grupa,'')<>''
		raiserror('Codul introdus nu face parte din grupa pentru care s-a deschis inventarul!',11,1)
	
	IF @update = 0
	BEGIN
		IF @idInventar IS NULL
			RAISERROR (
					'Este permisa doar modificarea pozitiilor unui inventar dupa ce acesta a fost adaugat. Utilizati operatiile "Deschidere inventar" si/sau "Populare inventar"'
					, 11, 1
					)
		ELSE
		begin
			if exists(select 1 from PozInventar where idInventar=@idInventar and cod=@cod)
				raiserror('Acest cod a fost scanat deja. Va rog frumos sa modificati pozitia corespunzatoare!',11,1)
			INSERT INTO PozInventar (idInventar, cod, stoc_faptic, utilizator, data_operarii, detalii)
			SELECT @idInventar, @cod, @stoc_faptic, @utilizator, GETDATE(), @detalii
		end
	END
	ELSE
		IF @update = 1
			UPDATE PozInventar
			SET stoc_faptic = @stoc_faptic, detalii=@detalii
			WHERE idPozInventar = @idPozInventar

	DECLARE @docPoz XML

	SET @docPoz = (SELECT @idInventar AS idInventar, @gestiune gestiune, @data data, @cautare as _cautare FOR XML raw)

	EXEC wIaPozInventar @sesiune = @sesiune, @parXML = @docPoz
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPozInventar)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
