create procedure validLMSalarii
as
begin try
	/*
		Se valideaza folosind tabela #lm (lm, data, utilizator)
			- apelare procedura standard
			- verificare validare stricta 
			- loc de munca validat pt. salarii
	*/

	/* Apelare procedura standard */
	exec validLM

	if exists(select 1 from #lm where cod='')
		raiserror('Loc de munca necompletat!',16,1)

	if exists (select 1 from #lm i inner join lm on i.Cod=lm.Cod
			inner join strlm s on lm.Nivel=s.Nivel and convert(int,s.Salarii)=0)
	raiserror('Locul de munca nu este validat pentru Salarii!',16,1)

end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validLMSalarii)'
	raiserror(@mesaj, 16,1)
end catch

