CREATE procedure wScriuLegaturiCRM @sesiune varchar(50), @parXML xml  
as 
begin try
	declare 
		@idContact int, @idPotential int

	select 
		@idContact=@parXML.value('(/*/@idContact)[1]','int'),
		@idPotential=@parXML.value('(/*/@idPotential)[1]','int')


	insert into LegaturiCRM (idContact, idPotential)
	select
		@idContact, @idPotential
	where NOT EXISTS (select 1 from LegaturiCRM where idContact=@idContact and idPotential=@idPotential)


end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
