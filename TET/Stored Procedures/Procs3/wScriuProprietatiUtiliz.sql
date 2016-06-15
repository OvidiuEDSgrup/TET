
CREATE PROCEDURE wScriuProprietatiUtiliz @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(50), @update BIT, @codproprietate VARCHAR(20), @valoare VARCHAR(200), @o_valoare VARCHAR(200),
		@o_codproprietate varchar(20), @ordine int

SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
SET @codproprietate = @parXML.value('(/row/@codproprietate)[1]', 'varchar(20)')
SET @valoare = @parXML.value('(/row/@valoare)[1]', 'varchar(200)')
SET @ordine = @parXML.value('(/row/@ordine)[1]','int')
SET @o_valoare = @parXML.value('(/row/@o_valoare)[1]', 'varchar(200)')
SET @update = @parXML.value('(/row/@update)[1]', 'bit')
set @o_codproprietate = @parXML.value('(/row/@o_codproprietate)[1]', 'varchar(20)')

BEGIN TRY
	if exists (select 1 from utilizatori u where u.ID=@utilizator and u.Marca='GRUP')
		raiserror('Acesta este un grup! Nu exista proprietati pe grupuri!',16,1)
	IF @update = 1 and @codproprietate<>@o_codproprietate
		raiserror('In modificare nu este permisa schimbarea codului proprietatii!',16,1)
	IF @update = 1
	BEGIN
		UPDATE proprietati
		SET Valoare = @valoare,
			Valoare_tupla = isnull(nullif(@ordine,''),0)
		WHERE tip = 'UTILIZATOR'
			AND cod = @utilizator
			AND Cod_proprietate = @codproprietate
			AND Valoare = @o_valoare
	END
	ELSE
	BEGIN
		INSERT INTO proprietati (Cod, Cod_proprietate, Tip, Valoare, Valoare_tupla)
		VALUES (@utilizator, @codproprietate, 'UTILIZATOR', @valoare, isnull(@ordine,0))
	END
END TRY

BEGIN CATCH
	DECLARE @eroare VARCHAR(900)

	SET @eroare = ERROR_MESSAGE()+' (wScriuProprietatiUtiliz)'

	RAISERROR (@eroare, 15, 11)
END CATCH
