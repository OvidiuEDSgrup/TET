
CREATE PROCEDURE wStergProprietatiUtiliz @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(50), @codprop VARCHAR(50), @valoare varchar(50)

SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
SET @codprop = @parXML.value('(/row/@codproprietate)[1]', 'varchar(50)')
SET @valoare = @parXML.value('(/row/@valoare)[1]', 'varchar(50)')

DELETE
FROM proprietati
WHERE tip = 'UTILIZATOR'
	AND cod = @utilizator
	AND Cod_proprietate = @codprop
	and valoare=@valoare

SELECT 'Valoare '+@valoare+' pe proprietatea ' + @codprop + ' a fost stearsa din dreptul utilizatorului' AS textMesaj, 'Notificare' AS titluMesaj
FOR XML raw, root('Mesaje')
