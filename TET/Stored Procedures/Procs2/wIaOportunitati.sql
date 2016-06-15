CREATE procedure wIaOportunitati @sesiune varchar(50), @parXML xml  
as 

	declare 
		@idPotential int, @f_descriere varchar(200), @f_topic varchar(200), @val_jos float, @val_sus float, @idLead int, @idOportunitate int, @datasus datetime, @datajos datetime

	/*
		RATING= H,W,C-> HOT, WARM, COLD -> vezi wIaRatingOportunitati
		STARE= C,P,D => Castigat, Pierdut, Inchis -> vezi wIaStariOportunitati

	*/
	select
		@idOportunitate=@parXML.value('(/*/@idOportunitate)[1]','int'),
		@idPotential=@parXML.value('(/*/@idPotential)[1]','int'),
		@idLead=@parXML.value('(/*/@idLead)[1]','int'),
		@datasus=ISNULL(@parXML.value('(/*/@datasus)[1]','datetime'),'01/01/2999'),
		@datajos=ISNULL(@parXML.value('(/*/@datajos)[1]','datetime'),'01/01/1900')

	select
		o.topic topic, o.descriere descriere, convert(varchar(10), o.data_inchiderii_estimata,101) termen, convert(varchar(10),o.data_operarii ,101) data,o.idPotential idPotential, o.idLead idLead,
		ISNULL(convert(decimal(15,2), o.vanzare_estimata),0) vanzare_estimata,
		 convert(varchar(10), o.probabilitate) probabilitate, o.rating as rating, (case rating when 'H' then 'Hot' when 'W' then 'Warm' else 'C' end) denrating,
		o.valuta valuta, rtrim(v.Denumire_valuta) denvaluta, o.stare stare, (case o.stare when 'C' then 'Castigat' when 'D' then 'Deschis' else 'Pierdut' end) denstare, o.supervizor supervizor,
		rtrim(u.nume) densupervizor, o.idOportunitate idOportunitate, o.detalii detalii
	from Oportunitati o
	left join valuta v on o.valuta=v.Valuta
	left join utilizatori u on o.supervizor=u.id	
	where 
		(@idLead IS NULL or o.idLead=@idLead) and
		(@idPotential IS NULL or o.idPotential=@idPotential) and 
		(@idOportunitate IS NULL or o.idOportunitate= @idOportunitate) and
		(o.data_operarii between @datajos and @datasus)
	for xml raw, root('Date')

	select 1 as areDetaliiXml
	for xml raw, root('Mesaje')
		
