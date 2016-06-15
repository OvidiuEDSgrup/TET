/***--
Procedura stocata scrie in tabela Inventar pozitiile operate
	
param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. 
--***/
CREATE PROCEDURE wmScriuWPozInv @sesiune VARCHAR(50), @parXML XML
AS
-- apelare procedura specifica daca aceasta exista.
IF EXISTS (SELECT 1 FROM sysobjects WHERE [type] = 'P' AND [name] = 'wmScriuWPozInvSP')
BEGIN
	DECLARE @returnValue INT
	EXEC @returnValue = wmScriuWPozInvSP @sesiune, @parXML
	RETURN @returnValue
END

DECLARE @userASiS VARCHAR(50), @mesaj VARCHAR(1000), @codProdus VARCHAR(100), @cant FLOAT, @codBare VARCHAR(50), @actiune VARCHAR(
		100), @msg VARCHAR(100), @idInventar INT, @idPozInventar INT, @detalii xml,@stare varchar(20), @grupa varchar(13), @gestiune varchar(13)

BEGIN TRY
	/*Validare utilizator */
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

	/*Citeste variabile din parametrii */
	SET @codProdus = @parXML.value('(/*/@cod)[1]', 'varchar(100)')
	SET @idInventar = @parXML.value('(/*/@idInventar)[1]', 'int')
	SET @idPozInventar = @parXML.value('(/*/@idPozInventar)[1]', 'int')
	SET @cant = @parXML.value('(/*/@cant)[1]', 'float')
	SET @msg = ISNULL(@parXML.value('(/*/@_mesaj)[1]', 'varchar(100)'), '')
	SET @codBare = ISNULL(@parXML.value('(/*/@codBare)[1]', 'varchar(50)'), '')
	SET @actiune = isnull(@parXML.value('(/*/@actiune)[1]', 'varchar(30)'), 'back(1)')

	if @cant is null -- procedura e apelata din scanare simpla, fara form de cantitate
		select @cant = isnull(stoc_faptic,0)+1 from pozinventar where idInventar=@idInventar and idPozInventar=@idPozInventar

	select @grupa= isnull(grupa,'') , @gestiune=ISNULL(gestiune,'')
	from AntetInventar where idInventar=@idInventar	
	
	--returnam eroare daca se introduce un cod care nu se gaseste in nomenclator
	if not exists(select 1 from nomencl where cod=@codProdus)
			RAISERROR ('Codul produsului nu a fost gasit in nomenclator!', 11, 1)
	
	---returnam eroare daca se introduce un cod care nu face parte din grupa de pe inventar
	if not exists(select 1 from nomencl where cod=@codProdus and grupa=@grupa) and ISNULL(@grupa,'')<>''
		raiserror('Codul introdus nu face parte din grupa pentru care s-a deschis inventarul!',11,1)

	IF (@idPozInventar is null)
	begin
		set @detalii='<row stare="scanat"/>'
	
		-- Se face insert.
		INSERT INTO PozInventar (idInventar, cod, data_operarii, stoc_faptic, utilizator, detalii)
		SELECT @idInventar, @codProdus, GETDATE(), @cant, @userASiS,@detalii
	end
	ELSE
	begin
		set @detalii = (select detalii from PozInventar where idPozInventar = @idPozInventar)
		set @stare='scanat'
		
		if @detalii is not null 
			if @detalii.value('(/row/@stare)[1]', 'varchar(20)') is not null 
				set @detalii.modify('replace value of (/row/@stare)[1] with sql:variable("@stare")') 
			else
				set @detalii.modify ('insert attribute stare {sql:variable("@stare")} into (/row)[1]') 
		else
			set @detalii='<row stare="scanat"/>'	
		-- Se face doar update cumulat
		UPDATE PozInventar
		SET Stoc_faptic =  @cant, Utilizator = @userASiS, Data_operarii = GETDATE(),detalii=@detalii
		WHERE idPozInventar = @idPozInventar
	end
	SELECT @actiune AS actiune
	FOR XML raw, root('Mesaje');
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wmScriuWPozInv)'
END CATCH

IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 11, 1)

