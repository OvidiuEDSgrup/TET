--***
/** procedura pentru citire date din RU_profesii **/
Create procedure wRUIaProfesii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaProfesiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaProfesiiSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200)
begin try
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select	top 100 rtrim(ID_profesie) as id_profesie, rtrim(denumire) as denumire, 
		rtrim(descriere) as descriere, rtrim(studii) as studii 			
	from RU_profesii
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaProfesii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
