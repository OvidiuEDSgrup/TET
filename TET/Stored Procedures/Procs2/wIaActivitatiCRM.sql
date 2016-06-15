CREATE procedure wIaActivitatiCRM  @sesiune varchar(50), @parXML xml  
as 

	declare
		@idSarcina int, @idOportunitate int, @idPotential int

	select
		@idSarcina = @parXML.value('(/*/@idSarcina)[1]','int'),
		@idOportunitate = @parXML.value('(/*/@idOportunitate)[1]','int'),
		@idPotential = @parXML.value('(/*/@idPotential)[1]','int')
	select
		convert(varchar(10), a.data, 101) data, a.marca marca, rtrim(p.nume) denmarca, a.tip_activitate tip_activitate, convert(varchar(10), a.termen,101) termen, a.note note, a.utilizator utilizator, a.detalii detalii,
		(case when @idSarcina IS NOT NULL then 'AT' end) as subtip, a.idActivitate idActivitate, a.idOportunitate idOportunitate, a.idPotential idPotential, a.idSarcina idSarcina
	from ActivitatiCRM a
	LEFT JOIN personal p on p.marca=a.marca
	where (@idSarcina = a.idSarcina or a.idOportunitate = @idOportunitate or a.idPotential=@idPotential)
	order by a.data desc
	for xml raw, root('Date')

	select 1 as areDetaliiXml for xml raw,root('Mesaje')
