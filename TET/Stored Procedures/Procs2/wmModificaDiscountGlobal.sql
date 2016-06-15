
create procedure wmModificaDiscountGlobal @sesiune varchar(50), @parXML xml
as

	declare 
		@discount float, @idComanda int

	set @discount=@parXML.value('(/*/@discount)[1]','float')
	set @idComanda=@parXML.value('(/*/@comanda)[1]','int')

	update PozContracte set discount=@discount where idContract=@idComanda and discount<>@discount
	update Contracte set detalii.modify('replace value of (/row/@discount)[1] with sql:variable("@discount")') where idContract=@idComanda

	select 'back(1)' as actiune for xml raw, root('Mesaje')
