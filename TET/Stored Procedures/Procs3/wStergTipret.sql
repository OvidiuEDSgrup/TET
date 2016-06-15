--***
Create 
procedure wStergTipret @sesiune varchar(50), @parXML xml
as

declare @subtip varchar(13), @mesajeroare varchar(200)
Set @subtip = @parXML.value('(/row/@subtip)[1]','varchar(13)')

set @mesajeroare=''
begin try
 select @mesajeroare=
 (case when exists (select 1 from benret r where tip_retinere=@subtip) then 'Codul de retinere selectat este folosit in beneficiar retineri!' else '' end)

if @mesajeroare=''	
	delete from tipret where subtip=@subtip
else 
	raiserror(@mesajEroare, 16, 1)
END TRY
BEGIN CATCH
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
--SELECT ERROR_MESSAGE() AS mesajeroare FOR XML RAW
END CATCH
