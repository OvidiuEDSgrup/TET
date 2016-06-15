
create procedure wIaJurnalOperatii @sesiune varchar(50), @parXML XML
as

	declare 
		@tip varchar(10), @datajos datetime, @datasus datetime

	select 
		@tip = @parXML.value('(/*/@tip)[1]','varchar(10)'),
		@datajos = @parXML.value('(/*/@datajos)[1]','varchar(10)'),
		@datasus = @parXML.value('(/*/@datasus)[1]','varchar(10)')

	select	
		convert(varchar(20),wj.data,101) data, convert(varchar(10),wj.data,108) ora, wj.utilizator utilizator, id
	from webjurnaloperatii wj 
	where wj.tip=@tip and convert(datetime,wj.data) between @datajos and @datasus
	order by wj.data desc
	for xml raw,root('Date')
