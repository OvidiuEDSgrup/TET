create procedure wStergCoduriVamale @sesiune varchar(50), @parXML xml 
as

declare @cod varchar(20), @mesajeroare varchar(100)
begin try		
	select
		@cod=isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),'')

	if exists (select 1 from nomencl where substring(Tip_echipament,2,20)=@cod)
		raiserror ('Acest cod vamal este atasat unui cod de nomenclator!',11,1)
	else
		delete from codvama	where Cod=@cod
end try
begin catch
	set @mesajeroare='(wStergCoduriVamale:)'+ ERROR_MESSAGE()
	raiserror (@mesajeroare,11,1)
end catch		  
