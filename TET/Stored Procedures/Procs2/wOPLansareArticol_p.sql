
CREATE PROCEDURE wOPLansareArticol_p @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @dentert VARCHAR(50), @comanda VARCHAR(20), @cod VARCHAR(20), @cantitate FLOAT

SET @dentert = @parXML.value('(/*/*/@tert)[1]', 'varchar(50)')
SET @comanda = @parXML.value('(/*/*/@comanda)[1]', 'varchar(20)')
SET @cod = @parXML.value('(/*/@cod)[1]', 'varchar(20)')
SET @cantitate = @parXML.value('(/*/*/@cantitate)[1]', 'float')

SELECT @dentert AS dentert, @comanda comanda, @cod cod, CONVERT(DECIMAL(15, 2), @cantitate) delansat
FOR XML raw, root('Date')
