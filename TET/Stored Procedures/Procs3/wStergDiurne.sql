--***
Create procedure wStergDiurne @sesiune varchar(50), @parXML xml
as
begin try
	declare @idPozitie int, @mesaj varchar(254), @mesajEroare varchar(254)
	Set @idPozitie = @parXML.value('(/row/@idPozitie)[1]','int')
	Select @mesaj='', @mesajEroare=''

	delete from diurne where idPozitie=@idPozitie
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+' (wStergDiurne)'
	raiserror(@mesaj, 11, 1)
end catch
