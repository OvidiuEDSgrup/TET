
/* Procedure de populare a machetei pentru raportul de set de antecalculatii (dupa numar de document de generare antecalculatii) **/
CREATE PROCEDURE wPopulareAntecalculatii @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @numarDoc VARCHAR(20)

SET @numarDoc = ISNULL(@parXML.value('(/row/@numarDoc)[1]', 'varchar(20)'), '')

SELECT @numarDoc AS nr_doc
FOR XML raw, root('Date')
