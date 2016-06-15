create procedure wOPAdaugaFisierTehnologie @sesiune varchar(50), @parXML XML  
as
	
	select @parXML.value('(/row/row/@id)[1]','int') pozitie for xml raw, root('Date')
