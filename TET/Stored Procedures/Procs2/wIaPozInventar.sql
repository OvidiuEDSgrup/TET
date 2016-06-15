
CREATE PROCEDURE [wIaPozInventar] @sesiune VARCHAR(50), @parXML XML
AS
if OBJECT_ID('wIaPozInventarSP') is not null
begin
	exec wIaPozInventarSP @sesiune=@sesiune, @parXML=@parXML
	return
end
DECLARE @idInventar INT, @tipg VARCHAR(20), @gestiune VARCHAR(20), @subunitate VARCHAR(13), @data DATETIME, @cautare varchar(200), @grupa varchar(13)

SET @idInventar = @parXML.value('(/*/@idInventar)[1]', 'int')
SET @gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)')
SET @grupa = @parXML.value('(/*/@grupa)[1]', 'varchar(13)')
SET @cautare = '%'+@parXML.value('(/*/@_cautare)[1]', 'varchar(100)')+ '%'
SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
SET @subunitate = '1'

SELECT TOP 1 @tipg = tip_gestiune
FROM gestiuni
WHERE Subunitate = @subunitate
	AND Cod_gestiune = @gestiune


SELECT top 100
	RTRIM(p.cod) AS cod,
	RTRIM(n.Denumire) AS denumire,
	CONVERT(DECIMAL(15, 2), p.stoc_faptic) AS stoc_faptic,
	RTRIM(p.utilizator) AS utilizator,
	'ID' AS subtip,
	p.idPozInventar AS idPozInventar,
	p.detalii 
FROM PozInventar p
INNER JOIN nomencl n ON n.Cod = p.cod
WHERE p.idInventar = @idInventar 
and (@cautare is null or p.cod like @cautare or n.Denumire like @cautare 
	or exists (select * from codbare cb where cb.cod_de_bare like @cautare and cb.cod_produs=p.cod))
FOR XML raw, root('Date')

select 1 areDetaliiXml for xml raw, root('Mesaje')
