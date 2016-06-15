create procedure wStergValute @sesiune varchar(50), @parXML xml 
as

declare @valuta varchar(8),@data varchar (50), @mesajeroare varchar(100),@curs float
begin try		
	select
		@valuta=isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),'')

	if exists (select 1 from curs where valuta=@valuta)
		raiserror ('Pe aceasta valuta au fost definite cursuri!',11,1)
	else
		delete from valuta	where  valuta=@valuta
end try
begin catch
	set @mesajeroare='(wStergValute:)'+ ERROR_MESSAGE()
	raiserror (@mesajeroare,11,1)
end catch		  
