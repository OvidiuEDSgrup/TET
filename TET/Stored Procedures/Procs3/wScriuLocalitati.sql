--***
create procedure wScriuLocalitati @sesiune varchar(50), @parXML xml
as 
declare	@mesaj varchar(500), @cod_localitate varchar(8), @localitate varchar(30), @judet varchar(30), 
		@cod_postal varchar(10), @extern bit, @update bit, @o_cod_localitate varchar(8)

begin try
	set @cod_localitate = isnull(@parXML.value('(/*/@cod_localitate)[1]','varchar(8)'),'')
	set @localitate = isnull(@parXML.value('(/*/@local)[1]','varchar(30)'),'')
	set @judet = isnull(@parXML.value('(/*/@jud)[1]','varchar(30)'),'')
	set @cod_postal = isnull(@parXML.value('(/*/@cod_postal)[1]','varchar(10)'),'')
	set @extern = isnull(@parXML.value('(/*/@extern)[1]','bit'),0)
	set @o_cod_localitate = isnull(@parXML.value('(/*/@o_cod_localitate)[1]','varchar(8)'),'')
	set @update = isnull(@parXML.value('(/*/@update)[1]','bit'),0)

	-- Se verirfica sa fie introdus un cod de localitate
	if @cod_localitate = ''
	begin
		set @mesaj = 'Cod localitate necompletat.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa fie un cod de localitate unic
	if exists(select 1 from Localitati l where l.cod_oras=@cod_localitate) and (@update=0)
	begin
		set @mesaj = 'Cod localitate existent.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa fie introdus numele localitatii
	if @localitate = ''
	begin
		set @mesaj = 'Nume localitate necompletata.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa fie introdus numele judetului
	if @judet = ''
	begin
		set @mesaj = 'Nume judet necompletat.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa fie un nume valid al unui judet
	if not exists(select 1 from Judete j where j.cod_judet=@judet)
	begin
		set @mesaj = 'Judet inexistent.'
		raiserror(@mesaj,16,1)
	end

	-- Se verifica sa nu fie numele unei localitati existente in acelasi judet
	if exists(select 1 from Localitati l where l.oras=@localitate and l.cod_judet=@judet)
	begin
		set @mesaj = 'Exista deja o localitate cu acest nume in acest judet.'
		raiserror(@mesaj,16,1)
	end

	if @update=0
	begin
		insert into Localitati(cod_oras, cod_judet, tip_oras, oras, cod_postal, extern)
		values (@cod_localitate, @judet, '', @localitate, @cod_postal, @extern)
	end
	else
	begin
		if exists(select 1 from Localitati where cod_oras=@localitate)
			set @localitate = (select oras from Localitati where cod_oras=@localitate)
		update Localitati set cod_oras=@cod_localitate, cod_judet=@judet, oras=@localitate, cod_postal=@cod_postal, extern=@extern
		where cod_oras=@o_cod_localitate
	end

	exec wIaLocalitati @sesiune, @parXML
end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wScriuLocalitati)'
	raiserror(@mesaj, 11, 1)	
end catch
