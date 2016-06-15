create procedure wStergUM @sesiune varchar(50), @parXML xml 
as

declare @UM varchar(8),@mesajeroare varchar(100)
begin try		
	select
		@UM=isnull(@parXML.value('(/row/@UM)[1]','varchar(3)'),'')

	if exists (select 1 from nomencl where Um=@UM or UM_1=@UM or UM_2=@UM)
		raiserror ('Aceasta unitate de masura este atribuita in nomenclator!',11,1)
	else
		delete from um	where um=@UM  
end try
begin catch
	set @mesajeroare='(wStergUM:)'+ ERROR_MESSAGE()
	raiserror (@mesajeroare,11,1)
end catch		  
