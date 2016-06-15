
create procedure wmAdaugaPozaNomencl @sesiune varchar(50), @parXML xml
as

declare
	@mesaj varchar(max), @cod varchar(20), @poza varchar(8000)

begin try
	select
		@cod = @parXML.value('(/row/@cod)[1]','varchar(20)'),
		@poza = @parXML.value('(/row/@poza)[1]','varchar(8000)')

	if exists(select 1 from pozeria where tip='N' and cod=@cod)
	begin
		update pozeria
			set fisier=@poza
		where tip='N' and cod=@cod
	end
	else
	begin
		insert into pozeria(tip,cod,fisier)
		select 'N',@cod,@poza
	end

	select 'back(2)' as actiune for xml raw,Root('Mesaje')
end try

begin catch
	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
