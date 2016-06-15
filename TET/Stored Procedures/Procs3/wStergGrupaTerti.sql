--***
create proc wStergGrupaTerti @sesiune varchar(250), @parXML xml
as

begin try
declare @grupa varchar(13), @mesaj varchar(500)
select
		@grupa=ISNULL(@parXML.value('(/row/@grupa)[1]','varchar(13)'),'')

if exists (select * from terti where /*Subunitate='1' and */Grupa = @grupa) 
begin  
	raiserror ('Grupa selectata nu poate fi stearsa pentru ca a fost atribuita la terti!',11,1)
	return -1
end	
else
begin
	delete from gterti where Grupa=@grupa 
end
end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1) 
end catch
