--***
Create 
procedure wStergBenret @sesiune varchar(50), @parXML xml
as

declare @cod varchar(13), @mesaj varchar(254), @mesajEroare varchar(254)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(13)')
Select @mesaj='', @mesajEroare=''
begin try
select @mesajEroare=
	(case when exists (select 1 from resal r where cod_beneficiar=@cod) then 'Codul de beneficiar selectat este folosit in retineri!' else '' end)
if @mesajEroare=''	
	delete from Benret where Cod_beneficiar=@cod
else 
	raiserror(@mesajEroare, 16, 1)
end try
begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
