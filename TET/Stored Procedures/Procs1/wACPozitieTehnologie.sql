
create procedure wACPozitieTehnologie @sesiune varchar(50), @parXML XML  
as

	declare 
		@cod_tehnologie varchar(20), @idTehnologie int

	select 
		@cod_tehnologie = @parXML.value('(/*/@cod_tehn)[1]','varchar(20)')

	select top 1 @idTehnologie = id from pozTehnologii where tip='T' and cod=@cod_tehnologie

	select
		id as cod, 
		ISNULL(c.denumire, n.denumire) denumire, 
		'Tip: '+(case p.tip when 'M' then 'Material' when 'O' then 'Operatie' when 'R' then 'Reper' else '' end) as info
	from pozTehnologii p
	LEFT JOIN Nomencl n on n.cod=p.cod and p.tip='M'
	LEFT JOIN Catop  c on c.cod=p.cod and p.tip='O'
	where p.parinteTop=@idTehnologie
	for xml raw, root('Date')
