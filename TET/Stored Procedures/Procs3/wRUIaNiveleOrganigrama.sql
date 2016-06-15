--***
Create procedure wRUIaNiveleOrganigrama @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaNiveleOrganigramaSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaNiveleOrganigramaSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200)
begin try
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
		
	select top 100 ID_nivel as id_nivel, Nivel_organigrama as nivel, rtrim(Descriere) as descriere
	from RU_nivele_organigrama
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaNiveleOrganigrama) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
