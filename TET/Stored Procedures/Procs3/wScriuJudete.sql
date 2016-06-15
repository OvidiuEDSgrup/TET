--***
create procedure wScriuJudete @sesiune varchar(50), @parXML xml
as 
declare	@mesaj varchar(500), @cod_judet varchar(3), @o_cod_judet varchar(3), @judet varchar(30), @prefix varchar(4), @update bit

begin try
	set @cod_judet = isnull(@parXML.value('(/*/@cod_judet)[1]','varchar(3)'),'')
	set @judet = isnull(@parXML.value('(/*/@judet_)[1]','varchar(30)'),'')
	set @prefix = isnull(@parXML.value('(/*/@prefix)[1]','varchar(4)'),'')
	set @o_cod_judet = isnull(@parXML.value('(/*/@o_cod_judet)[1]','varchar(3)'),'')
	set @update = isnull(@parXML.value('(/*/@update)[1]','bit'),0)

	if @cod_judet = ''
	begin
		set @mesaj = 'Cod judet necompletat.'
		raiserror(@mesaj, 16, 1)
	end
	
	if exists(select 1 from Judete j where j.cod_judet=@cod_judet) and (@update=0)
	begin
		set @mesaj = 'Cod judet existent.'
		raiserror(@mesaj,16,1)
	end

	if @update=0
	begin
		insert into Judete(cod_judet,denumire,prefix_telefonic)
		values(@cod_judet,@judet,@prefix)
	end
	else
	begin
		if exists(select 1 from Judete where cod_judet=@judet)
			set @judet = (select denumire from Judete where cod_judet=@judet)
		update Judete set cod_judet=@cod_judet, denumire=@judet, prefix_telefonic=@prefix
		where cod_judet=@o_cod_judet
	end

	exec wIaJudete @sesiune, @parXML
end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wScriuJudete)'
	raiserror(@mesaj, 11, 1)
end catch
