
CREATE PROCEDURE wACGestLMMarcaInventar @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(200), @tip VARCHAR(2), @tipinventar VARCHAR(1)

SET @tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)')
SET @searchText = '%' + isnull(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') + '%'
SET @tipinventar = isnull(@parXML.value('(/row/@tipinventar)[1]', 'varchar(1)'),(case when @tip='ID' then 'G' else 'M' end))

IF @tipinventar = 'G'
BEGIN
	EXEC wACGestiuni @sesiune = @sesiune, @parXML = @parXML

	RETURN
END

IF @tipinventar = 'L'
BEGIN
	EXEC wACLocm @sesiune = @sesiune, @parXML = @parXML

	RETURN
END

IF @tipinventar = 'M'
BEGIN
	EXEC wACPersonal @sesiune = @sesiune, @parXML = @parXML

	RETURN
END
