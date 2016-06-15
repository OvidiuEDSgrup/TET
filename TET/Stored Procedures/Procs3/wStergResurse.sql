create procedure wStergResurse @sesiune varchar(50), @parXML XML
as
	declare @id int 
	set @id=isnull(@parXML.value('(/row/@id)[1]','int'),-1)
	
	delete from resurse where id=@id
	delete from OpResurse where idRes=@id
