
create procedure wScriuRetetaCod @sesiune varchar(50), @parXML xml
as
begin try
	declare	
		@cod varchar(20), @parinteTop int, @cantitate float, @cod_nomencl varchar(20), @cod_tehnologie varchar(20), @update bit, @id int

	select
		@cod_nomencl=@parXML.value('(/*/@cod)[1]','varchar(20)'),
		@cod=@parXML.value('(/*/*/@cod)[1]','varchar(20)'),
		@id=@parXML.value('(/*/*/@id)[1]','int'),
		@cantitate=@parXML.value('(/*/*/@cantitate)[1]','float'),
		@update=ISNULL(@parXML.value('(/*/*/@update)[1]','bit'),0)

	select top 1
		@parinteTop=ptehn.id
	from tehnologii t
	JOIN pozTehnologii ptehn on t.cod=ptehn.cod and ptehn.tip='T'
	where t.codNomencl=@cod_nomencl

	IF @UPDATE=0
	BEGIN
		if @cod_nomencl= @cod	
			raiserror('Codul caruia ii definim reteta nu poate fi in componenta lui insusi',16,1)
		if exists (select 1 from pozTehnologii where cod=@cod and idp=@parinteTop)
			raiserror('Acest element exista deja in reteta pe nivelul curent',16,1)
	
		IF ISNULL(@parinteTop,0)=0
		begin
			insert into tehnologii(cod, Denumire, tip, Data_operarii, detalii, codNomencl)
			select @cod_nomencl, rtrim(denumire), 'P', GETDATE(),nULL, @cod_nomencl
			from NOmencl where cod=@cod_nomencl
			insert into pozTehnologii (tip, cod)
			select 'T',@cod_nomencl

			select @parinteTop=IDENT_CURRENT('poztehnologii')
	
		end
		insert into pozTehnologii(tip, cod, cantitate,pret,idp,parinteTop)
		select 'M',@cod, @cantitate,0, @parinteTop, @parinteTop
	END
	else
		update pozTehnologii
			set cantitate=@cantitate
		WHERE ID=@ID


end try
begin catch
	declare @mesaj varchar(max)
	set @mesaj= ERROR_MESSAGE() + ' (wScriuRetetaCod)'
	raiserror(@mesaj, 16,1)
end catch
