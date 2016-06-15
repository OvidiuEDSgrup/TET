--***
/** procedura pentru citire date din RU_indicatori_ob **/
Create procedure wRUIaIndicatori_ob @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaIndicatori_obSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaIndicatori_obSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @id_obiectiv int
begin try
	select @id_obiectiv = isnull(@parXML.value('(/row/@id_obiectiv)[1]','int'),0)
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select	top 100 rtrim(a.ID_ind_ob) as id_ind_ob, rtrim(a.ID_obiectiv) as id_obiectiv, 
		rtrim(a.descriere) as descriere, rtrim(a.valori) as valori,rtrim(a.procent) as procent
	from RU_indicatori_ob a where a.id_obiectiv=@id_obiectiv
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaIndicatori_ob) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
