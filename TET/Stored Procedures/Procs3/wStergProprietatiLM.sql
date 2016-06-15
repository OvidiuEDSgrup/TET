
create proc wStergProprietatiLM @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@lm varchar(20), @cod_prop varchar(20), @valoare varchar(20)

	select 
		@lm = rtrim(@parXML.value('(/*/@lm)[1]','varchar(20)')),
		@cod_prop = rtrim(@parXML.value('(/*/*/@codproprietate)[1]','varchar(20)')),
		@valoare = rtrim(@parXML.value('(/*/*/@valoare)[1]','varchar(20)'))

	delete from proprietati
	where tip = 'LM' and cod = @lm and cod_proprietate = @cod_prop
		and valoare = @valoare
		
end try
begin catch
	declare @mesaj varchar(500)
	set @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesaj, 16, 1)
end catch
