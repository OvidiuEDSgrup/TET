
CREATE PROCEDURE wOPAtribuireSarcina_p @sesiune VARCHAR(50), @parXML XML
AS

	select 
		'' marca, '' denmarca, '' data, '' termen, '' tip_sarcina, '' descriere, 1 prioritate, 0 'update', 'N' stare
	for xml raw, root('Date')
