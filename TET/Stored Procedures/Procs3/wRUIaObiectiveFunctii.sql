--***
Create procedure wRUIaObiectiveFunctii @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaObiectiveFunctiiSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaObiectiveFunctiiSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @codfunctie varchar(6)
begin try
	select 
		@codfunctie=ISNULL(@parXML.value('(/row/@cod)[1]','varchar(6)'),0)

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select top 100 c.ID_ob_functii as id_ob_functii, c.ID_obiectiv as id_obiectiv, 
		rtrim(c.Cod_functie) as codfunctie, convert(decimal(12,2),c.Pondere) as pondere, 
		rtrim(co.Denumire) as denobiectiv, rtrim(co.Categorie) as ob_categorie, 
		(case when co.Categorie='1' then 'Companie' when co.Categorie='2' then 'Departament' when co.Categorie='3' then 'Individual' else '' end) as dencategorie,
		rtrim(co.Actiuni_realizare) as ob_actiuni_realizate
	from RU_obiective_functii c
		inner join RU_obiective co on c.ID_obiectiv=co.ID_obiectiv
	where c.Cod_functie=@codfunctie
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaObiectiveFunctii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)	

