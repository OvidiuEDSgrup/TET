--***
/** procedura pentru citire date contact din RU_persoane **/
Create procedure wRUIaPersoaneDateContact @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaPersoaneDateContactSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaPersoaneDateContactSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @id_pers int
begin try
	select 
		@id_pers=ISNULL(@parXML.value('(/row/@id_pers)[1]','int'),0)
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select	top 100 rtrim(a.Telefon_fix) as telefon_fix, rtrim(a.Telefon_mobil) as telefon_mobil,
		rtrim(email)as email, rtrim(a.Idmessenger) as idmessenger, rtrim(a.Idfacebook) as idfacebook,
		rtrim(a.openid) as openid
	from RU_persoane a 
	where ID_pers=@id_pers
	for xml raw
end try
begin catch
	set @mesaj = '(wRUIaPersoaneDateContact)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
