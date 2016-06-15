
CREATE procedure wScriuContacte @sesiune varchar(50), @parXML xml  
as 
begin try
	declare 
		@idContact int, @nume varchar(200), @email varchar(200), @telefon varchar(200), @adresa varchar(500),
		@profil varchar(200), @note varchar(max), @update bit, @mesaj varchar(max)

	select
		@idContact=@parXML.value('(/*/@idContact)[1]','int'),
		@update=ISNULL(@parXML.value('(/*/@update)[1]','bit'),0),
		@nume=@parXML.value('(/*/@nume)[1]','varchar(200)'),
		@email=@parXML.value('(/*/@email)[1]','varchar(200)'),
		@telefon=@parXML.value('(/*/@telefon)[1]','varchar(200)'),
		@adresa=@parXML.value('(/*/@adresa)[1]','varchar(500)'),
		@profil=@parXML.value('(/*/@profil)[1]','varchar(200)'),
		@note=@parXML.value('(/*/@note)[1]','varchar(max)')


	if @update=0
	begin
		insert into Contacte(nume,email, telefon, adresa, profil, note)
		select
			@nume, @email, @telefon, @adresa, @profil, @note
	end
	else
		IF @update=1
		begin
			update Contacte 
				set nume=@nume, email=@email, telefon=@telefon, adresa=@adresa, profil=@profil, note=@note
			where idContact=@idContact
		end


end try
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
