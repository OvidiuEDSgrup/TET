
create procedure wStergLeaduri @sesiune varchar(50), @parXML XML
as

	declare @idLead int

	set @idLead=@parXML.value('(/*/@idLead)[1]','int')

	delete from LEaduri where idLead=@idLead
