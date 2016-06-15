
CREATE PROCEDURE wStergRezultatTehnologie @sesiune VARCHAR(50), @parXML XML
AS

	delete pozTehnologii where id=@parXML.value('(/*/@idLinie)[1]','int')

	exec wIaRezultatTehnologie @sesiune=@sesiune, @parXML=@parXML
