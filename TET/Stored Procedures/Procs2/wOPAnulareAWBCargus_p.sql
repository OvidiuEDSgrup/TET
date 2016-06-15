	
create procedure wOPAnulareAWBCargus_p @sesiune varchar(50), @parXML xml 
as
	declare @idContract int

	select @idContract=@parXML.value('(/*/@idContract)[1]','int')


	select awb awb, 1 as anulare from Contracte where idContract=@idContract for xml raw,root('Date')
