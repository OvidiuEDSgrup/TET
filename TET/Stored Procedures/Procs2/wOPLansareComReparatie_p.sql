
CREATE PROCEDURE wOPLansareComReparatie_p @sesiune VARCHAR(50), @parXML XML
AS
SELECT @parXML.value('(/*/@masina)[1]', 'varchar(20)') AS codmasina, @parXML.value('(/*/@den_masina)[1]', 'varchar(80)') AS 
	denmasina, @parXML.value('(/*/@denumire)[1]', 'varchar(20)') AS denelement
FOR XML raw, root('Date')
