
CREATE PROCEDURE wRapComenziProductie_p @sesiune VARCHAR(50), @parXML XML
AS

	select 
		convert(varchar(10),dbo.BOM(GETDATE()),101) datajos, 
		convert(varchar(10), dbo.EOM(GETDATE()),101) datasus, 
		@parXML.value('(/*/@comanda)[1]','varchar(20)') comanda
	for xml raw, root('Date')

