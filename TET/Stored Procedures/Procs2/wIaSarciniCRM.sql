CREATE procedure wIaSarciniCRM @sesiune varchar(50), @parXML xml  
as 

	declare 
		@idSesizare int, @idPotential int,@idOportunitate int,@f_marca varchar(200), @f_stare varchar(200), @f_descriere varchar(200), @datajos datetime, @datasus datetime, @idSarcina int

	select
		@idSesizare= @parXML.value('(/*/@idSesizare)[1]','int'),
		@idPotential= @parXML.value('(/*/@idPotential)[1]','int'),
		@idSarcina= @parXML.value('(/*/@idSarcina)[1]','int'),
		@idOportunitate= @parXML.value('(/*/@idOportunitate)[1]','int'),
		@datasus = ISNULL(@parXML.value('(/*/@datasus)[1]','datetime'),'01/01/2900'),
		@datajos = ISNULL(@parXML.value('(/*/@datajos)[1]','datetime'),'01/01/1900')


	select
		s.idSarcina idSarcina, s.idOportunitate idOportunitate, s.idPotential idPotential, s.idSesizare idSesizare,
		s.tip_sarcina tip_sarcina, 	s.marca marca, rtrim(p.nume) denmarca, s.descriere descriere, convert(varchar(10), s.termen,101) termen, s.prioritate prioritate, s.stare stare,
		(case s.stare when 'L' then 'In lucru' when 'F' then 'Finalizata' when 'N' then 'Nepreluata' end) denstare, convert(varchar(10), s.data, 101) data, s.detalii detalii,
		(case s.stare when 'L' then '#0000FF' when 'F' then '#C0C0C0' when 'N' then '#FF0000' end) culoare
	from SarciniCRM s 
	LEFT JOIN Personal p on s.marca=p.marca
	where 
		(s.idOportunitate=@idOportunitate OR s.idSesizare=@idSesizare OR s.idPotential= @idPotential OR (@idOportunitate IS NULL and @idSesizare IS NULL and @idPotential IS NULL)) AND
		s.data between @datajos and @datasus and
		(@idSarcina IS NULL or s.idSarcina = @idSarcina)
	order by s.data desc, termen, prioritate 
	for xml raw, root('Date')

	select '1' as areDetaliiXml for xml raw, root('Mesaje')



