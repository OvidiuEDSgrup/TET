
CREATE PROCEDURE wStergNomenclatorImpl @sesiune varchar(50), @parXML xml
AS
	DECLARE @antetXML xml, @grupa varchar(13)

	/** Trimitem grupa la wIa... ca sa aduca produsele ce fac parte din grupa trimisa. */
	SELECT @grupa = @parXML.value('(/row/@grupa)[1]', 'varchar(13)')
	SET @antetXML = (SELECT @grupa AS grupa FOR XML RAW)

	EXEC wStergNomenclator @sesiune = @sesiune, @parXML = @parXML

	/** Apelam wStergGrupe doar daca nu are produse si nu este parinte.
		Daca se doreste modificarea unei grupe din macheta "Date implementare",
		va trebuie stearsa intai. */
	IF NOT EXISTS (SELECT 1 FROM nomencl WHERE grupa = @grupa) AND NOT EXISTS (SELECT 1 FROM grupe WHERE grupa_parinte = @grupa)
		EXEC wStergGrupe @sesiune = @sesiune, @parXML = @antetXML

	EXEC wIaNomenclatorImpl @sesiune = @sesiune, @parXML = @antetXML
