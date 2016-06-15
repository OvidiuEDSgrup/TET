
CREATE PROCEDURE wIaConsumuriComanda_p @sesiune VARCHAR(50), @parXML XML
as
	select @parXML.value('(/*/@comanda)[1]','varchar(20)') f_comanda for xml raw, root('Date')
