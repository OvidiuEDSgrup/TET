
CREATE PROCEDURE wOPAlocareToateRap_p @sesiune VARCHAR(50), @parXML XML
AS
SELECT 1 AS alocat
FOR XML raw, root('Date')
