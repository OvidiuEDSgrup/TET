
CREATE PROCEDURE wACFacturiContracte @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @xml xml, @searchText varchar(200)
	SELECT @searchText = @parXML.value('(/row/@searchText)[1]', 'varchar(200)')

	/** Pot fi mai multe facturi, pentru mai multe contracte care au data diferita. 
		Aducem facturile cu tipul AP. */
	SET @xml =
	(
		SELECT '' AS data, 'AP' AS tip, @searchText AS searchText FOR XML RAW
	)
	EXEC wACFacturi @sesiune = @sesiune, @parXML = @xml

END
