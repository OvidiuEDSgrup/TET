CREATE procedure wOPGenerarePotentialClient_p @sesiune varchar(50), @parXML xml  
as 

	declare 
		@idLead int

	set @idLead = @parXML.value('(/*/@idLead)[1]','int')

	select
		denumire_firma dentert, topic topic, nume contact, note note, domeniu_activitate domeniu, telefon telefon, email email, 'Oportunitate in domeniul ' + domeniu_activitate descriere
	from Leaduri 
	for xml raw, root('Date')
