--***
Create procedure wRUIaNiveleFunctii @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaNiveleFunctiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaNiveleFunctiiSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @Cod_functie char(6)
begin try
	select @Cod_functie=ISNULL(@parXML.value('(/row/@cod)[1]','char(6)'),0)
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
		
	select top 100 n.ID_nivel_functie as id_nivel_functie, n.ID_nivel as id_nivel, 
		rtrim(n.Cod_functie_parinte) as codfunctieparinte, rtrim(n.Cod_functie) as codfunctie, 
		CONVERT(varchar(10),n.data_inceput,101) as data_inceput, CONVERT(varchar(10),n.Data_sfarsit,101) as data_sfarsit,
		o.Nivel_organigrama as nivel, rtrim(o.Descriere) as descrierenivel, RTRIM(f.Denumire) as denfunctieparinte
	from RU_nivele_functii n
		left outer join functii f on n.Cod_functie_parinte=f.Cod_functie
		left outer join RU_nivele_organigrama o on n.ID_nivel=o.ID_nivel
	where n.Cod_functie=@cod_functie
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaNiveleFunctii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
