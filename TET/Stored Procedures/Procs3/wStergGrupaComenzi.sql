--***
create proc wStergGrupaComenzi @sesiune varchar(250), @parXML xml
as

begin try
declare @tipcom varchar(1), @grupa varchar(13), @denumire varchar(30), @mesaj varchar(500)
select
		@tipcom=ISNULL(@parXML.value('(/row/@tipcom)[1]','varchar(1)'),''),
		@grupa=ISNULL(@parXML.value('(/row/@grupa)[1]','varchar(13)'),''),
		@denumire=ISNULL(@parXML.value('(/row/@denumire)[1]','varchar(30)'),'')

if exists (select * from pozcom where Subunitate='GR' and Cod_produs = @grupa) 
begin  
	raiserror ('Grupa selectata nu poate fi stearsa pentru ca a fost atribuita in comenzi!',11,1)
	return -1
end	
else
begin
	delete from grcom where Tip_comanda=@tipcom and Grupa=@grupa 
end
end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1) 
end catch
