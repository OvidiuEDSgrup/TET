
CREATE PROCEDURE wOPOfertaLucrare_p @sesiune VARCHAR(50), @parXML XML
AS
	
	select @parXML.value('(/*/@idAntec)[1]','int') id_antecalculatie for xml raw, root('Date')
