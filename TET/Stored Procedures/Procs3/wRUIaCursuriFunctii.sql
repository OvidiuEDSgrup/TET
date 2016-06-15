--***
/** Procedura pt. luare cursuri pe functii **/
Create procedure wRUIaCursuriFunctii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaCursuriFunctiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaCursuriFunctiiSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @codfunctie varchar(6), @id_curs int, @tip varchar(2)
begin try
	select @codfunctie = isnull(@parXML.value('(/row/@cod)[1]','char(6)'),''), 
		@id_curs = @parXML.value('(/row/@id_curs)[1]','int'), 
		@tip = isnull(@parXML.value('(/row/@tip)[1]','char(2)'),'')
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select top 100 'CS' as tip, rtrim(a.ID_curs_functie) as id_curs_functie, rtrim(a.Cod_functie) as codfunctie, rtrim(f.Denumire) as denfunctie, 
		rtrim(a.ID_curs) as id_curs, rtrim(b.Denumire) as dencurs
	from RU_cursuri_functii a
		left outer join RU_cursuri b on b.ID_curs=a.ID_curs
		left outer join functii f on f.Cod_functie=a.Cod_functie
	where (@id_curs is null and a.Cod_functie=@codfunctie or @id_curs is not null and a.ID_curs=@id_curs)
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaCursuriFunctii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)