--***
Create procedure wRUIaDomenii @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaDomeniiSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaDomeniiSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200)
begin try
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
		
	select top 100 rtrim(ID_domeniu) as id_domeniu, rtrim(Denumire) as denumire, rtrim(Descriere) as descriere
	from RU_domenii
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaDomenii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
