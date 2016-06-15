
--***
CREATE PROCEDURE wOPPopulareInventar_p @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @datainv DATETIME, @denGestiune VARCHAR(50), @gestiune VARCHAR(9)

SELECT @datainv = isnull(@parXML.value('(/*/@data)[1]', 'datetime'), '2999-01-01'), @denGestiune = isnull(@parXML.value(
			'(/*/@dengestiune)[1]', 'varchar(50)'), ''), @gestiune = isnull(@parXML.value('(/*/@gestiune)[1]', 'varchar(9)'), 
		'')

SELECT convert(VARCHAR(20), @datainv, 101) data, @dengestiune dengestiune, @gestiune gestiune
FOR XML raw
