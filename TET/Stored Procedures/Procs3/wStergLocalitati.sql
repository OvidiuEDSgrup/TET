--***
create procedure wStergLocalitati @sesiune varchar(50), @parXML xml
as 
declare	@mesaj varchar(500), @cod_localitate varchar(8)

begin try
	set @cod_localitate = isnull(@parXML.value('(/*/@cod_localitate)[1]','varchar(8)'),'')

	if @cod_localitate = ''
	begin
		set @mesaj = 'Cod localitate inexistent.'
		raiserror(@mesaj,16,1)
	end
	else
	begin
		delete from Localitati where cod_oras=@cod_localitate
	end

	exec wIaLocalitati @sesiune, @parXML
end try

begin catch
	set @mesaj = ERROR_MESSAGE() + '(wStergLocalitati)'
	raiserror(@mesaj, 11, 1)	
end catch
