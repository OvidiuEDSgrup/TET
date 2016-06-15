Create procedure wOPRefacereInregistrariContabileDocument @sesiune varchar(50), @parXML xml
as
/*
	exec wOPRefacereInregistrariContabileDocument @sesiune='', @parXML='<row tip_document="RS" numar="" data="" />'
*/

	declare
		@tipdoc varchar(20), @nrdoc varchar(40), @data datetime, @subunitate varchar(9)

	select
		@tipdoc = COALESCE(@parXML.value('(/*/@tip_document)[1]', 'varchar(2)'),@parXML.value('(/*/@tipdoc)[1]', 'varchar(2)'),@parXML.value('(/*/@tip)[1]', 'varchar(2)'), ''),
		@nrdoc = COALESCE(@parXML.value('(/*/@numar)[1]', 'varchar(40)'),@parXML.value('(/*/@nrdoc)[1]', 'varchar(40)'),@parXML.value('(/*/@cont)[1]', 'varchar(40)')),
		@data = @parXML.value('(/*/@data)[1]', 'datetime')
	
	exec luare_date_par 'GE','SUBPRO',0,0, @subunitate OUTPUT

	exec faInregistrariContabile @dintabela=0, @subunitate=@subunitate, @tip=@tipdoc, @numar=@nrdoc, @data=@data
