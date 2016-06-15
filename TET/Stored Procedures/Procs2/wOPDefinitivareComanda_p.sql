
--***
CREATE PROCEDURE wOPDefinitivareComanda_p @sesiune VARCHAR(30), @parXML XML
AS
SELECT '' AS contract
FOR XML raw, root('Date')
