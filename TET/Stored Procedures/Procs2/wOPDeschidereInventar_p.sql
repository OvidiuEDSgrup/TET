
create procedure wOPDeschidereInventar_p @sesiune varchar(50), @parXML xml
as
	select '' gestiune, convert(varchar(10), GETDATE(), 101) data for xml raw, root('Date')
