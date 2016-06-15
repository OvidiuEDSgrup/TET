
CREATE procedure wACEfectePlati @sesiune varchar(50), @parXML XML  
as  

	set @parXML.modify('delete (/row/@tipefect)[1]')
	set @parXML.modify('insert attribute tipefect {"P"} into (/row)[1]')
	
	exec wACEfecte @sesiune=@sesiune, @parXML=@parXML
