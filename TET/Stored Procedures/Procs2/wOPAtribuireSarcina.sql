
CREATE PROCEDURE wOPAtribuireSarcina @sesiune VARCHAR(50), @parXML XML
AS

	if @parXML.value('(/*/@update)[1]', 'varchar(9)') is not null                          
		set @parXML.modify('replace value of (/*/@update)[1] with ("0")') 

	exec wScriuSarciniCRM @sesiune=@sesiune, @parXML=@parXML
