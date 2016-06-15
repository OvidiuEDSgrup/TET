
create procedure wOPAdaugPersoanaDelegat @sesiune varchar(50), @parXML xml
as

declare 
	@tert varchar(20), @nume varchar(150), @prenume varchar(150), @seriebuletin varchar(10), @numarbuletin varchar(10), @eliberatbuletin varchar(50),
	@functie varchar(50), @judet varchar(2), @localitate varchar(100), @info2 varchar(500), @email varchar(100), @telefon varchar(20), @info7 varchar(500),
	@_butonAdaugare bit, @xml xml, @mesaj varchar(max)

begin try

	select
		@tert = rtrim(@parXML.value('(/*/detalii/row/@tertdelegat)[1]','varchar(20)')),
		@nume = rtrim(@parXML.value('(/*/@nume)[1]', 'varchar(150)')),
		@prenume = rtrim(@parXML.value('(/*/@prenume)[1]', 'varchar(150)')),
		@seriebuletin = rtrim(@parXML.value('(/*/@seriebuletin)[1]', 'varchar(10)')),
		@numarbuletin = rtrim(@parXML.value('(/*/@numarbuletin)[1]', 'varchar(10)')),
		@eliberatbuletin = rtrim(@parXML.value('(/*/@eliberatbuletin)[1]', 'varchar(50)')),
		@functie = rtrim(@parXML.value('(/*/@functie)[1]', 'varchar(50)')),
		@judet = rtrim(@parXML.value('(/*/@judet)[1]', 'varchar(2)')),
		@localitate = rtrim(@parXML.value('(/*/@localitate)[1]', 'varchar(100)')),
		@info2 = rtrim(@parXML.value('(/*/@info2)[1]', 'varchar(500)')),
		@email = rtrim(@parXML.value('(/*/@email)[1]', 'varchar(100)')),
		@telefon = rtrim(@parXML.value('(/*/@telefon)[1]', 'varchar(20)')),
		@info7 = rtrim(@parXML.value('(/*/@info7)[1]', 'varchar(500)')),
		@_butonAdaugare = isnull(@parXML.value('(/*/@_butonAdaugare)[1]', 'bit'),0)

	select @xml = 
	(
		select
			@tert as tert,
			@nume as nume,
			@prenume as prenume,
			@seriebuletin as seriebuletin,
			@numarbuletin as numarbuletin,
			@eliberatbuletin as eliberatbuletin,
			@functie as functie,
			@judet as judet,
			@localitate as localitate,
			@info2 as info2,
			@email as email,
			@telefon as telefon,
			@info7 as info7,
			@_butonAdaugare as _butonAdaugare
		for xml raw
	)

	exec wScriuPersoaneContact @sesiune = @sesiune, @parXML = @xml
end try

begin catch
	set @mesaj = error_message() + ' (' + object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch
