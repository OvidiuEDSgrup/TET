
CREATE PROCEDURE wIaPozDateCentralizatorPlanificare @sesiune VARCHAR(50), @parXML XML
AS

	declare 
		@idAntet int

	set @idAntet=@parXML.value('(/*/@idAntet)[1]','int')

	select
		op.cod as operatie, rtrim(c.Denumire) as denoperatie, pp.cod comanda,convert(decimal(15,2),op.cantitate) cant_op, p.idAntet idAntet,
		convert(decimal(15,2),pp.cantitate) cant_re, rtrim(n.Denumire) denreper, rtrim(n.cod) cod_re, p.id idPlanificare
	from planificare p
	JOIN pozLansari op on op.id=p.idOp
	JOIN pozLansari pp on pp.id=op.parinteTop
	JOIN pozTehnologii pt on pt.id=pp.idp
	JOIN tehnologii t on t.cod=pt.cod
	JOIN nomencl n on n.cod=t.codNomencl
	JOIN catop c on c.Cod=op.cod
	where p.idantet=@idAntet
	for xml raw, root('Date')
