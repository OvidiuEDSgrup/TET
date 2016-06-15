CREATE PROCEDURE wOPStergDateProcesate @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @comenzi BIT, @facturi BIT, @incasari BIT

SET @comenzi = @parXML.value('(/parametri/@comenzi)[1]', 'bit')
SET @facturi = @parXML.value('(/parametri/@facturi)[1]', 'bit')
SET @incasari = @parXML.value('(/parametri/@incasari)[1]', 'bit')

IF @comenzi = 1
	DELETE dateSincronizare
	WHERE tip = 'C'
		AND STATUS = 'ok'

IF @facturi = 1
	DELETE dateSincronizare
	WHERE tip = 'F'
		AND STATUS = 'ok'

IF @incasari = 1
	DELETE dateSincronizare
	WHERE tip = 'S'
		AND STATUS = 'ok'
