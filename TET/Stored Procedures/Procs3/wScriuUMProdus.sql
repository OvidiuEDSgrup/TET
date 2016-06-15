
create procedure wScriuUMProdus @sesiune varchar(50), @parXML XML
as
	declare 
		@cod varchar(20), @um varchar(3), @coeficient float, @update bit

	select 
		@cod = @parXML.value('(/row/@cod)[1]','varchar(20)'),
		@coeficient = @parXML.value('(/row/row/@coeficient)[1]','float'),
		@um = @parXML.value('(/row/row/@um)[1]','varchar(3)'),
		@update = ISNULL(@parXML.value('(/row/row/@update)[1]','bit'),0)


	IF EXISTS (select 1 from nomencl where cod=@cod and um=@um)
		RAISERROR('Unitatea de masura specificata este unitatea de masura de baza a produsului si nu este necesara adaugare ei!',15,1)

	IF EXISTS (select 1 from UMProdus where cod=@cod and um=@um and @update=0)
		RAISERROR('Unitatea de masura specificata este asociata deja prodului!',15,1)

	IF @update=0
		insert into UMProdus (cod, um, coeficient)
		select @cod, @um, @coeficient
	
	IF @update=1
		update UMProdus
			set coeficient=@coeficient
		where cod=@cod and um=@um
