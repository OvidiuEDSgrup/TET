--***
/** procedura pentru citire furnizori pe cursuri - detaliere pe catalogul de cursuri **/
Create procedure wRUIaFurnizoriCursuri @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaFurnizoriCursuriSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaFurnizoriCursuriSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @id_curs int, @sub varchar(9)
begin try
	select @id_curs = isnull(@parXML.value('(/row/@id_curs)[1]','int'),0)
	set @sub=dbo.iauParA('GE','SUBPRO')
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select top 100 rtrim(a.ID_furnizor_curs) as id_furnizor_curs, rtrim(a.ID_curs) as id_curs, rtrim(a.Tert) as tert, rtrim(t.Denumire) as dentert,
		convert(decimal(10,3),a.Pret) as pret, rtrim(a.UM) as um, rtrim(u.Denumire) as denum, rtrim(a.Explicatii) as explicatii
	from RU_furnizori_cursuri a 
		left outer join terti t on t.Subunitate=@sub and t.Tert=a.Tert
		left outer join UM u on u.UM=a.UM
	where a.ID_curs=@id_curs
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaFurnizoriCursuri) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
