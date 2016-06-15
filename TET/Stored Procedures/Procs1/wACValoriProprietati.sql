
CREATE PROCEDURE wACValoriProprietati @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100), @proprietate VARCHAR(50), @tipValidare SMALLINT, @catalogValidare VARCHAR(2), @utilizator 
	VARCHAR(100)

SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
SET @searchText = '%' + REPLACE(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '%'), ' ', '%') + '%'
SET @proprietate = @parXML.value('(/row/@codproprietate)[1]', 'varchar(50)')

SELECT top 1  @tipValidare = validare, @catalogValidare = CATALOG
FROM catproprietati
WHERE Cod_proprietate = @proprietate

IF @tipValidare = 0
BEGIN
	SET @searchText = REPLACE(@searchText, '%', '')

	SELECT @searchText AS cod, @searchText AS denumire, @searchText AS info
	FOR XML raw, root('Date')
END
ELSE
	IF @tipValidare = 1
		SELECT vp.Valoare AS cod, vp.Descriere AS denumire, 'Valori posibile' AS info
		FROM valproprietati vp
		INNER JOIN catproprietati cpr ON cpr.Cod_proprietate = vp.Cod_proprietate
		WHERE cpr.Cod_proprietate = @proprietate
		FOR XML raw, root('Date')
	ELSE
		IF @tipValidare = 2
		BEGIN
			IF @catalogValidare = 'N'
				EXEC wACNomenclator @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'T'
				EXEC wACTerti @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'G'
				EXEC wACGestiuni @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'L'
				EXEC wACLocm @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'C'
				EXEC wACComenzi @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'U'
				EXEC wACUM @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'V'
				EXEC wACValuta @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'M'
			begin
				if exists(select 1 from sys.objects where name='Masini_Masini' and type = 'U')
					EXEC wACMasiniNoi @sesiune = @sesiune, @parXML = @parXML
				else
					EXEC wACMasini @sesiune = @sesiune, @parXML = @parXML
			end

			IF @catalogValidare = 'E'
				EXEC wACOperatii @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'S'
				EXEC wACSalariati @sesiune = @sesiune, @parXML = @parXML

			IF @catalogValidare = 'O'
				EXEC wACConturi @sesiune = @sesiune, @parXML = @parXML
		END
