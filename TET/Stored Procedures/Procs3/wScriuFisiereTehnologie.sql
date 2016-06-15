
create procedure wScriuFisiereTehnologie @sesiune varchar(50), @parXML XML  
as
begin try
	declare 
		@idPozTehnologie int, @fisier varchar(200), @observatii varchar(200), @pozitie int, @idFisier int, 
		@update bit

	select 
		@idPozTehnologie = @parXML.value('(/*/@idTehn)[1]','int'),
		@idFisier = @parXML.value('(/*/@idFisier)[1]','int'),
		@fisier = @parXML.value('(/*/@fisier)[1]','varchar(200)'),
		@observatii = @parXML.value('(/*/@observatii)[1]','varchar(200)'),
		@pozitie = NULLIF(@parXML.value('(/*/@pozitie)[1]','int'),0),
		@update = ISNULL(@parXML.value('(/*/@update)[1]','int'),0)


	IF ISNULL(@idFisier,0)=0
		insert into FisiereProductie(fisier, idPozTehnologie, observatii)
		select @fisier, ISNULL(@pozitie, @idPozTehnologie), @observatii
	ELSE 
		IF @update=1
			update FisiereProductie
				set observatii=@observatii
			where idFisier=@idFisier
		
	/*
		Tabelul FisiereProductie permite in dreptul tehnologiilor ca o compnentan (ex. o operatie) poate avea mai multe fisiere atasate
		De regula, operatiile vor avea 1 desen (exemplu). Pt. a permite descarcarea rapida a acestui fisier din macheta de pozitii a tehnologiilor
			vom salva linkul complet catre fisier in detalii xml a pozitiei- si il intretinem aici
	*/
	IF @pozitie IS NOT NULL and ISNULL(@idFisier,0)=0
	begin
		declare 
			@detalii XML, @desen varchar(300)


		select @detalii=detalii from pozTehnologii where id=@pozitie
		select 
			@desen= char(60)+'a href="formulare/uploads/'+ RTRIM(@fisier) +'" target="_blank" /><u> Click </u></a>'
		FROM par WHERE Tip_parametru = 'AR' AND Parametru = 'URL' 

		IF @detalii IS NOT NULL
		begin
			set @detalii.modify('delete (/*/@desen)[1]')
			set @detalii.modify('insert attribute desen {sql:variable("@desen")} into (/row)[1]')
		end
		else
			set @detalii=(select @desen desen for xml raw,type)

		update pozTehnologii set detalii=@detalii where id=@pozitie
	end
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
