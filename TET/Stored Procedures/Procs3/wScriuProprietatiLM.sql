
create proc wScriuProprietatiLM @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@lm varchar(20), @cod_prop varchar(20), @update bit, @valoare varchar(20)

	select 
		@lm = rtrim(@parXML.value('(/*/@lm)[1]', 'varchar(20)')),
		@cod_prop = rtrim(@parXML.value('(/row/row/@codproprietate)[1]', 'varchar(20)')),
		@valoare = rtrim(@parXML.value('(/row/row/@valoare)[1]', 'varchar(20)')),
		@update = isnull(@parXML.value('(/row/row/@update)[1]', 'bit'), 0)

	if @update = 1
		update proprietati
			set valoare = @valoare
		where tip = 'LM' and cod = @lm and cod_proprietate = @cod_prop
	else
		insert into proprietati (tip, cod, cod_proprietate, valoare, valoare_tupla)
		select
			'LM', @lm, @cod_prop, @valoare, ''
		where not exists (select 1 from proprietati where tip = 'LM' and cod = @lm and cod_proprietate = @cod_prop
			and valoare = @valoare) 
		
end try
begin catch
	declare @mesaj varchar(500)
	set @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror (@mesaj, 15, 1)
end catch
