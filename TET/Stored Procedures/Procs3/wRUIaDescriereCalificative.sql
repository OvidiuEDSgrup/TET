--***
/* Procedura pt. descriere calificative */
Create procedure wRUIaDescriereCalificative @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaDescriereCalificativeSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaDescriereCalificativeSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @id_calificativ int
begin try
	select @id_calificativ = isnull(@parXML.value('(/row/@id_calificativ)[1]','int'),0)
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
		
	select	top 100 rtrim(a.ID_descriere) as id_descriere, rtrim(a.ID_calificativ) as id_calificativ, 
		rtrim(a.Descriere_calificativ) as descriere_calificativ
	from RU_descriere_calificative a where a.ID_calificativ=@id_calificativ
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaDescriereCalificative) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
