
/** Asociere plaje: sugerare cod in functie de tip asociere
	U: Utilizator
	L: Loc de munca
	J: Jurnale
	G: Grup utilizatori
	'': Unitate
*/
CREATE PROCEDURE wACCodAsocierePlaja @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100), @tipAsociere VARCHAR(2)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%'
SET @tipAsociere = @parXML.value('(/*/@tipasociere)[1]', 'varchar(2)')

IF @tipAsociere = 'L'
BEGIN
	EXEC wACLocm @sesiune = @sesiune, @parXML = @parXML

	RETURN
END

IF @tipAsociere = 'U'
BEGIN
	EXEC wACUtilizatori @sesiune = @sesiune, @parXML = @parXML

	RETURN
END

IF @tipAsociere = 'J'
BEGIN
	EXEC wACJurnale @sesiune = @sesiune, @parXML = @parXML

	RETURN
END
