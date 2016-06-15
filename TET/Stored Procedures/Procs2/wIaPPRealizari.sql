CREATE PROCEDURE wIaPPRealizari @sesiune VARCHAR(50), @parXML XML
AS
	declare
		@idRealizare int, @pp xml
	set @idRealizare=@parXML.value('(/*/@idRealizare)[1]','int')

	set @pp=(
		SELECT top 1
			'PP' tip, CONVERT(varchar(10), Data,101) data, '1' subunitate, rtrim(Numar) numar
		from pozdoc where subunitate='1' and Tip='PP' and detalii is not null and detalii.value('(/*/@idRealizare)[1]','int')=@idRealizare
		for xml raw
		)

	exec wIaDoc @sesiune=@sesiune, @parXML=@pp
