CREATE PROCEDURE wIaCMRealizari @sesiune VARCHAR(50), @parXML XML
AS
	declare
		@idRealizare int, @cm xml
	set @idRealizare=@parXML.value('(/*/@idRealizare)[1]','int')

	set @cm=(
		SELECT top 1
			'CM' tip, CONVERT(varchar(10), Data,101) data, '1' subunitate, rtrim(Numar) numar
		from pozdoc where subunitate='1' and Tip='CM' and detalii is not null and detalii.value('(/*/@idRealizare)[1]','int')=@idRealizare
		for xml raw
		)

	exec wIaDoc @sesiune=@sesiune, @parXML=@cm
