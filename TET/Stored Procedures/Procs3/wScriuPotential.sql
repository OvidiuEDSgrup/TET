CREATE procedure wScriuPotential @sesiune varchar(50), @parXML xml  
as 
begin try
	declare
		@denumire varchar(200), @cod_fiscal varchar(200), @localitate varchar(200), @note varchar(200), @update bit, @utilizator varchar(100), @detalii XML, @idPotential int


	select
		@denumire=@parXML.value('(/*/@dentert)[1]','varchar(200)'),
		@cod_fiscal=@parXML.value('(/*/@cod_fiscal)[1]','varchar(30)'),
		@localitate=@parXML.value('(/*/@localitate)[1]','varchar(200)'),
		@note=@parXML.value('(/*/@note)[1]','varchar(200)'),
		@idPotential=@parXML.value('(/*/@idPotential)[1]','int'),
		@update=ISNULL(@parXML.value('(/*/@update)[1]','bit'),0)

		if @parXML.exist('(/*/detalii)[1]')=1
			SET @detalii = @parXML.query('(/*/detalii/row)[1]')

	IF NOT EXISTS (select 1 from Localitati where cod_oras=@localitate)
		select top 1 @localitate=ISNULL(cod_oras,'') from Localitati where Localitati.oras=@localitate
	
	IF ISNULL(@cod_fiscal,'')<>'' and EXISTS (select 1 from Potentiali where cod_fiscal=@cod_fiscal) and @update=0
		raiserror('Exista un potential client cu acest cod fiscal!',16,1)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	IF @update = 0 
	BEGIN
		insert into Potentiali(cod_fiscal,denumire,cod_localitate,note,data_operatii,supervizor, detalii)
		select @cod_fiscal, @denumire,@localitate, @note, GETDATE(), @utilizator, @detalii

		select @idPotential=IDENT_CURRENT('potentiali')
	end
	else
		update 
			Potentiali set denumire=@denumire, note=@note, supervizor=@utilizator, data_operatii=GETDATE(), detalii=@detalii, cod_fiscal= @cod_fiscal
		where idPotential= @idPotential

	set @parXML=(select @idPotential idPotential for xml raw)
	exec wIaPotentialiClienti @sesiune=@sesiune, @parXML=@parXML

	select (case when @update=1 then 0 end) as 'close' for xml raw, root('Mesaje')
end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
