
CREATE procedure wIaSesizariCRM @sesiune varchar(50), @parXML xml  
as 

	
	declare 
		@idPotential int, @tert varchar(20), @tip_sesizare varchar(100), @descriere varchar(200), @stare varchar(20), @datasus datetime, @datajos datetime


	select 
		@datajos=ISNULL(@parXML.value('(/*/@datajos)[1]','datetime'),'01/01/1901'),
		@datasus=ISNULL(@parXML.value('(/*/@datasus)[1]','datetime'),'01/01/2901'),
		@idPotential= @parXML.value('(/*/@idPotential)[1]','int')


	select 
		s.idSesizare idSesizare, s.idSesizare id, s.tip_sesizare tip_sesizare, s.descriere descriere, s.supervizor supervizoe,rtrim(u.nume) densupervizor, 
		s.note note, s.stare stare, s.detalii detalii, (case s.stare when 'N' then 'Nepreluata' when 'L' then 'In lucru' when 'F' then 'Finalizata' end ) denstare,
		(case s.stare when 'N' then '#FF0000' when 'L' then '#0000FF' when 'F' then '#C0C0C0' end ) culoare, s.idPotential idPotential, p.denumire dentert,
		convert(varchar(10), s.data, 101) data
	from SesizariCRM s
	LEFT JOIN utilizatori u on s.supervizor=u.id
	LEFT JOIN Potentiali p on p.idPotential=s.idPotential
	where (@idPotential IS NULL OR @idPotential=s.idPotential )
	order by data_operatii desc
	for xml raw, root('Date')

	select 1 as areDetaliiXml
	for xml raw,root('Mesaje')
