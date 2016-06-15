--***
/** Procedura pt. luare competente resurse umane pe functii **/
Create procedure wRUIaCompetenteFunctii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaCompetenteFunctiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaCompetenteFunctiiSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @codfunctie varchar(6)
begin try
	select @codfunctie = isnull(@parXML.value('(/row/@cod)[1]','char(6)'),0)
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select top 100 'FC' as tip, rtrim(a.ID_comp_functii) as id_comp_functii, rtrim(a.ID_competenta) as id_competenta,
	rtrim(a.Cod_functie) as codfunctie, rtrim(b.Denumire) as dencompetenta, RTRIM(pondere) as pondere
	from RU_competente_functii a
		left outer join RU_competente b on b.ID_competenta=a.ID_competenta 
	where a.Cod_functie=@codfunctie
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaCompetenteFunctii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)