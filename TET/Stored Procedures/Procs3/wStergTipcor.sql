--***
Create 
procedure wStergTipcor @sesiune varchar(50), @parXML xml
as

declare @subtip varchar(13), @mesajEroare varchar(200)
Set @subtip = @parXML.value('(/row/@subtip)[1]','varchar(13)')

set @mesajEroare=''
begin try
	select @mesajEroare=
	(case when exists (select 1 from corectii r where tip_corectie_venit=@subtip) then 'Codul de retinere selectat este folosit in corectii!' else '' end)

if @mesajEroare=''	
	delete from subtipcor where subtip=@subtip
else 
	raiserror(@mesajEroare, 16, 1)
END TRY
BEGIN CATCH
	set @mesajEroare=ERROR_MESSAGE()
	raiserror(@mesajEroare, 11, 1)
--SELECT ERROR_MESSAGE() AS mesajeroare FOR XML RAW
END CATCH
