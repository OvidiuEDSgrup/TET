
create procedure wScriuStructLM (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(1000), @nivel int, @denumire varchar(30), @lungime int, @o_nivel int,
		@doc bit, @mf bit, @sal bit, @cost bit, @prod bit, @dev bit, @update bit

begin try
	set @nivel = isnull(@parXML.value('(/row/@nivel)[1]','int'),0)
	set @denumire = isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),'')
	set @lungime = isnull(@parXML.value('(/row/@lungime)[1]','int'),0)
	set @doc = isnull(@parXML.value('(/row/@doc)[1]','bit'),0)
	set @mf = isnull(@parXML.value('(/row/@mf)[1]','bit'),0)
	set @sal = isnull(@parXML.value('(/row/@sal)[1]','bit'),0)
	set @cost = isnull(@parXML.value('(/row/@cost)[1]','bit'),0)
	set @prod = isnull(@parXML.value('(/row/@prod)[1]','bit'),0)
	set @dev = isnull(@parXML.value('(/row/@dev)[1]','bit'),0)
	set @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0)
	set @o_nivel = isnull(@parXML.value('(/row/@o_nivel)[1]','int'),0)
	if (@nivel <= 0)
	begin
		set @mesaj = 'Nivelul trebuie sa fie mai mare decat 0.'
		raiserror(@mesaj,16,1)
	end

	if (@denumire = '')
	begin
		set @mesaj = 'Campul denumire necompletat.'
		raiserror(@mesaj,16,1)
	end

	if (@lungime <= 0)
	begin
		set @mesaj = 'Lungimea trebuie sa fie mai mare decat 0.'
		raiserror(@mesaj,16,1)
	end

	if exists(select 1 from strlm where Nivel=@nivel and @update=0)
	begin
		set @mesaj = 'Nivelul este deja definit in structura locurilor de munca.'
		raiserror(@mesaj,16,1)
	end

	if exists(select 1 from strlm where Nivel=@nivel and @nivel<>@o_nivel and @update=1)
	begin
		set @mesaj = 'Nivelul este deja definit in structura locurilor de munca.'
		raiserror(@mesaj,16,1)
	end

	if exists(select 1 from strlm where (Lungime >= @lungime) and (Nivel=@nivel-1))
	begin
		set @mesaj = 'Lungimea trebuie sa fie mai mare decat lungimea nivelului superior.'
		raiserror(@mesaj,16,1)
	end

	if exists(select 1 from strlm where (Lungime <= @lungime) and (Nivel=@nivel+1))
	begin
		set @mesaj = 'Lungimea trebuie sa fie mai mica decat lungimea nivelului inferior.'
		raiserror(@mesaj,16,1)
	end

	if (@update=1)
	begin
		update strlm set Nivel=@nivel, Denumire=@denumire, Lungime=@lungime,
				Documente=@doc, Mijloace_fixe=@mf, Salarii=@sal, Costuri=@cost, Produse=@prod, Devize=@dev
		where Nivel=@o_nivel
	end
	else
	begin
		insert into strlm(Nivel,Denumire,Lungime,Documente,Mijloace_fixe,Salarii,Costuri,Produse,Devize)
		values (@nivel,rtrim(@denumire),@lungime,@doc,@mf,@sal,@cost,@prod,@dev)
	end
end try


begin catch
	set @mesaj = error_message() + ' (wScriuStructLM)'
	raiserror(@mesaj, 11, 1)
end catch
