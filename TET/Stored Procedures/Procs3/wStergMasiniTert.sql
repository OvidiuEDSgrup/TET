
CREATE PROCEDURE wStergMasiniTert @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @tert varchar(50), @nr_masina varchar(50)
	SELECT @tert = @parXML.value('(/row/@tert)[1]', 'varchar(50)'),
		@nr_masina = @parXML.value('(/row/row/@nr_masina)[1]', 'varchar(50)')

	DELETE FROM masinexp
	WHERE Numarul_mijlocului = @nr_masina AND Furnizor = @tert
END
