
CREATE PROCEDURE wScriuCategoriiPreturi @sesiune varchar(50), @parXML xml
AS

DECLARE
	@utilizator varchar(50), @categoriepret smallint, @tipcategoriepret smallint,
	@dencategorie varchar(30), @invaluta bit, @cudiscount bit, @suma float, @categref int,
	@update int, @mesaj varchar(500), @o_categoriepret smallint, @o_dencategorie varchar(30),
	@detalii xml

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT 
		@categoriepret = ISNULL(@parXML.value('(/row/@categoriepret)[1]','smallint'), 0),
		@tipcategoriepret = ISNULL(@parXML.value('(/row/@tipcategoriepret)[1]','smallint'), 0),
		@dencategorie = ISNULL(@parXML.value('(/row/@dencategorie)[1]','varchar(30)'), ''),
		@invaluta = ISNULL(@parXML.value('(/row/@invaluta)[1]','bit'), 0),
		@cudiscount = ISNULL(@parXML.value('(/row/@cudiscount)[1]','bit'), 0),
		@suma = ISNULL(@parXML.value('(/row/@suma)[1]','float'), 0),
		@categref = ISNULL(@parXML.value('(/row/@categref)[1]','int'), 0),
		@update = ISNULL(@parXML.value('(/row/@update)[1]','int'), 0),
		@o_categoriepret = ISNULL(@parXML.value('(/row/@o_categoriepret)[1]','smallint'), 0),
		@o_dencategorie = ISNULL(@parXML.value('(/row/@o_dencategorie)[1]','varchar(30)'), '')

		IF @parXML.exist('(/*/detalii)[1]') = 1
			SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	IF @update = 1 -- validare in mod modificare
	BEGIN
		IF @categoriepret <> @o_categoriepret -- daca se modifica categoria pretului
		BEGIN
			RAISERROR('Nu se poate modifica categoria pretului. Poate fi referita de o alta categorie!', 15, 1)
			RETURN -1
		END
		ELSE IF @categref = @o_categoriepret
		BEGIN
			RAISERROR('Nu se poate referi pe sine insusi!', 15, 1)
			RETURN -1
		END
		ELSE IF @categoriepret = '' OR @tipcategoriepret = '' OR @dencategorie = ''
		BEGIN
			RAISERROR('Trebuie completate categoria, tipul categoriei si denumirea!', 11, 1)
			RETURN -1
		END
		ELSE IF EXISTS ( SELECT 1 FROM categpret WHERE Denumire = @dencategorie)
					AND @dencategorie <> @o_dencategorie
		BEGIN
			RAISERROR('Denumirea categoriei deja exista!', 11, 1)
			RETURN -1
		END
	END

	IF @update = 0 -- mod adaugare
	BEGIN
		IF EXISTS ( SELECT 1 FROM categpret WHERE Categorie = @categoriepret) OR
			EXISTS ( SELECT 1 FROM categpret WHERE Denumire = @dencategorie) -- daca categoria introdusa exista deja in baza de date
		BEGIN
			RAISERROR('Categoria deja exista!', 11, 1)
			RETURN -1
		END
		ELSE IF @categoriepret = '' OR @tipcategoriepret = '' OR @dencategorie = '' -- daca nu s-au completat campurile Categorie, Tip categorie, Denumire
		BEGIN
			RAISERROR('Trebuie completate categoria, tipul categoriei si denumirea!', 11, 1)
			RETURN -1
		END
		ELSE
			INSERT INTO categpret(Categorie, Tip_categorie, Denumire, In_valuta, Cu_discount, Suma, categ_referinta, detalii) -- inserarea propriu-zisa
				SELECT @categoriepret, @tipcategoriepret, @dencategorie, @invaluta, @cudiscount, @suma, @categref, @detalii
	END
	ELSE -- mod modificare
	BEGIN
		UPDATE categpret
			SET Categorie = @categoriepret, Tip_categorie = @tipcategoriepret, Denumire = @dencategorie, 
					In_valuta = @invaluta, Cu_discount = @cudiscount, Suma = @suma, categ_referinta = @categref,
					detalii = @detalii
		WHERE Categorie = @categoriepret
	END 

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuCategoriiPreturi)'
	RAISERROR(@mesaj, 11, 1)
END CATCH
