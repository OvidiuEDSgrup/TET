
CREATE PROCEDURE wScriuRezultatTehnologie @sesiune VARCHAR(50), @parXML XML
AS
begin try
	declare
		@idTehnologie int, @cod varchar(20), @cantitate float,@update bit, @id int,@detalii xml

	select
		@idTehnologie=@parXML.value('(/*/@idTehn)[1]','int'),
		@cod=@parXML.value('(/*/*/@cod)[1]','varchar(20)'),
		@id=@parXML.value('(/*/*/@idLinie)[1]','int'),
		@update=ISNULL(@parXML.value('(/*/*/@update)[1]','bit'),0),
		@cantitate=ISNULL(@parXML.value('(/*/*/@cantitate)[1]','float'),0)


	IF EXISTS (select 1 from pozTehnologii pt join tehnologii t on pt.cod=t.cod and pt.tip='T' and pt.id=@idTehnologie and t.tip <> 'S')
			raiserror('Doar tehnologia de tip Serviciu permite operarea de rezultate!',15,1)

	IF @update= 0
		INSERT INTO pozTehnologii (tip, cod, cantitate, idp, parinteTop,  detalii)
		select 'Z', @cod, @cantitate, @idTehnologie, @idTehnologie, @detalii

	else
		update pozTehnologii	
			set cod=@cod, cantitate=@cantitate 
		where id=@id and @update=1

	exec wIaRezultatTehnologie @sesiune=@sesiune, @parXML=@parXML


end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
