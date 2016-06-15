CREATE procedure wPopulareTabSarciniOportunitate  @sesiune varchar(50), @parXML xml  
as

	select @parXML.value('(/*/@idOportunitate)[1]','int') idOportunitate for xml raw, root('Date')
