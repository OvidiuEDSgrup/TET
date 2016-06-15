
--***
CREATE PROCEDURE wScriuOperatii @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'wScriuOperatiiSP'
			AND type = 'P'
		)
	EXEC wScriuOperatiiSP @sesiune, @parXML
ELSE
BEGIN
	DECLARE @cod VARCHAR(10), @denumire VARCHAR(50), @o_cod VARCHAR(20), @UM VARCHAR(50), @tipoperatie VARCHAR(50), @categorie 
		VARCHAR(50), @tarif float, @nrpersoane VARCHAR(50), @nrpozitii VARCHAR(50), @normatimp FLOAT, @comanda VARCHAR(max), 
		@err VARCHAR(100), @modificare INT

	SET @cod = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(10)'), ''))
	SET @o_cod = rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(10)'), ''))
	SET @denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(50)'), ''))
	SET @UM = rtrim(isnull(@parXML.value('(/row/@UM)[1]', 'varchar(50)'), ''))
	SET @tipoperatie = rtrim(isnull(@parXML.value('(/row/@tipoperatie)[1]', 'varchar(50)'), ''))
	SET @nrpozitii = rtrim(isnull(@parXML.value('(/row/@nrpozitii)[1]', 'varchar(50)'), ''))
	SET @nrpersoane = rtrim(isnull(@parXML.value('(/row/@nrpersoane)[1]', 'varchar(50)'), ''))
	SET @categorie = rtrim(isnull(@parXML.value('(/row/@categorie)[1]', 'varchar(50)'), ''))
	SET @tarif = rtrim(isnull(@parXML.value('(/row/@tarif)[1]', 'float'), ''))
	SET @normatimp = rtrim(isnull(@parXML.value('(/row/@normatimp)[1]', 'float'), 0))
	SET @modificare = isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

	--Update
	IF @modificare = 1
	BEGIN
		UPDATE catop
		SET Cod = @cod, Denumire = @denumire, UM = @UM, Tip_operatie = @tipoperatie, Numar_persoane = @nrpersoane, Numar_pozitii = 
			@nrpozitii, Tarif = @tarif, Categorie = @categorie
		WHERE Cod = @o_cod
	END

	--Insert
	IF @modificare = 0
	BEGIN
		IF EXISTS (
				SELECT Cod
				FROM catop
				WHERE Cod = @cod
				)
		BEGIN
			SET @err = (
					SELECT 'Codul de operatie ' + @cod + ' exista deja!'
					)

			RAISERROR (@err, 16, 1)

			RETURN;
		END
		ELSE
			INSERT INTO catop (Cod, Denumire, UM, Tip_operatie, Numar_pozitii, Numar_persoane, Tarif, Categorie)
			VALUES (@cod, @denumire, @um, @tipoperatie, @nrpozitii, @nrpersoane, @tarif, @categorie)
	END

	IF EXISTS (
			SELECT 1
			FROM syscolumns sc, sysobjects so
			WHERE so.id = sc.id
				AND so.NAME = 'catop'
				AND sc.NAME = 'Norma_timp'
			)
	BEGIN
		SET @comanda = 'update catop set norma_timp=''' + CONVERT(VARCHAR(max), @normatimp) + ''' where cod=''' + @cod + ''''

		EXEC (@comanda)

		RETURN
	END
END
