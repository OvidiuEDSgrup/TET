CREATE procedure wPopulareOportunitate @sesiune varchar(50), @parXML xml  
as 
	select 0 as 'update', @parXML.value('(/*/@idPotential)[1]','int') idPotential 
	for xml raw, root('Date')
