
CREATE PROCEDURE wOPRaportProductie_p @sesiune varchar(50), @parXML xml
AS
	declare @idRealizare int

	set @idRealizare=@parXML.value('(/*/@idRealizare)[1]','int')

	select TOP 1 
		nrDoc numar, convert(varchar(10),data,101) data
	from Realizari where id=@idRealizare
	for xml raw , ROOT('Date')
