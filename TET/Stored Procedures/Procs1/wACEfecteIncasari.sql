
CREATE procedure wACEfecteIncasari @sesiune varchar(50), @parXML XML  
as  

	set @parXML.modify('delete (/row/@tipefect)[1]')
	set @parXML.modify('insert attribute tipefect {"I"} into (/row)[1]')
	
	exec wACEfecte @sesiune=@sesiune, @parXML=@parXML
