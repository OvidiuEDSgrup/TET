--***
create procedure wStergJudete @sesiune varchar(50), @parXML xml
as 
declare	@mesaj varchar(500), @cod_judet varchar(3)

begin try
	set @cod_judet = isnull(@parXML.value('(/*/@cod_judet)[1]','varchar(3)'),'')

	if @cod_judet = ''
	begin
		set @mesaj = 'Cod judet inexistent.'
		raiserror(@mesaj,16,1)
	end
	else
	begin
		delete from Judete where cod_judet=@cod_judet
	end

	exec wIaJudete @sesiune, @parXML
end try

begin catch
	set @mesaj = ERROR_MESSAGE() + '(wStergLocalitati)'
	raiserror(@mesaj, 11, 1)	
end catch
