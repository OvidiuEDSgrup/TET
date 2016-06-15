
create procedure wScriuExceptiiSoldTert @sesiune varchar(50), @parXML XML
as

IF EXISTS (select 1 from sys.objects where name = 'wScriuExceptiiSoldTertSP')
	exec wScriuExceptiiSoldTertSP @sesiune=@sesiune, @parXML=@parXML OUTPUT

declare
	@mesaj varchar(max), @tert varchar(13), @idExceptie int, @dela datetime, @panala datetime, @ora_start varchar(5), @ora_stop varchar(5), 
	@sold_max float, @explicatii varchar(500), @utilizator varchar(100), @update bit

begin try
	select
		@tert = rtrim(@parXML.value('(/row/@tert)[1]','varchar(13)')),
		@idExceptie = @parXML.value('(/row/row/@idExceptie)[1]','int'),
		@panala = isnull(@parXML.value('(/row/row/@panala)[1]','datetime'),convert(varchar(10),getdate(),101)),
		@ora_stop = isnull(@parXML.value('(/row/row/@ora_stop)[1]','varchar(5)'),'00:00'),
		@sold_max = isnull(@parXML.value('(/row/row/@sold_max)[1]','float'),0.0),
		@explicatii = isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(500)'),''),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	if @utilizator is null
		return

	if @ora_stop not like '[0-2][0-9]:[0-9][0-9]'
		raiserror('Ora trebuie sa fie in formatul HH:MM',16,1)

	if @explicatii=''
		raiserror('Completati campul cu explicatii.',16,1)

	select
		@panala = dateadd(day,datediff(day,0,@panala),@ora_stop)

	if @update=0
	begin
		insert into ExceptiiSoldTert(tert,dela,panala,sold_max,explicatii,utilizator,data_operarii)
		select @tert, getdate(), @panala, @sold_max, @explicatii, @utilizator, getdate()
	end
	else
	begin
		raiserror('Exceptia nu poate fi modificata.',16,1)
		--update ExceptiiSoldTert
		--set
		--	panala=@panala,
		--	sold_max=@sold_max,
		--	explicatii=@explicatii,
		--	utilizator=@utilizator,
		--	data_operarii=getdate()
		--where idExceptie=@idExceptie
	end
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch
