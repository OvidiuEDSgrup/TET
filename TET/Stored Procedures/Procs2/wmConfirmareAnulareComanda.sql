
create procedure wmConfirmareAnulareComanda @sesiune varchar(50), @parXML xml  
as
set transaction isolation level read uncommitted

if exists(select * from sysobjects where name='wmConfirmareAnulareComandaSP' and type='P')  
begin
	exec wmConfirmareAnulareComandaSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end

declare 
	@mesaj varchar(max), @comanda int, @cod int

begin try
	select 
		@cod = isnull(@parXML.value('(/row/@cod)[1]','int'),0),
		@comanda = isnull(@parXML.value('(/row/@comanda)[1]','int'),0)

	if @cod=0 or @comanda=0
	begin
		select 'back(2)' as actiune for xml raw, Root('Mesaje')
	end
	
	if @cod=1
	begin
		delete from JurnalContracte where idContract=@comanda
		delete from PozContracte where idContract=@comanda
		delete from Contracte where idContract=@comanda

		select 'back(3)' as actiune for xml raw, Root('Mesaje')
	end
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
