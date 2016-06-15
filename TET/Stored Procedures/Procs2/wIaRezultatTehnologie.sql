
CREATE PROCEDURE wIaRezultatTehnologie @sesiune VARCHAR(50), @parXML XML
AS

	declare @idTehnologie int

	set @idTehnologie=@parXML.value('(/*/@idTehn)[1]','int')


	select
		pt.cod cod, rtrim(n.denumire) denumire, convert(decimal(15,2), pt.cantitate) cantitate, pt.id idLinie, 'Z' subtip
	from pozTehnologii pt
	JOIN Nomencl n on pt.cod=n.cod and pt.tip='Z'
	where pt.parinteTop=@idTehnologie
	for xml raw, root('Date')
