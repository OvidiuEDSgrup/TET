--***
/** procedura pentru date buletin **/
Create procedure wRUIaPersoaneBI @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaPersoaneBISP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaPersoaneBISP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @id_pers int
begin try
	select 
		@id_pers=ISNULL(@parXML.value('(/row/@id_pers)[1]','int'),0)
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select	top 100 rtrim(a.cnp) as cnp, rtrim(a.serie_bi) as serie_bi, rtrim(a.numar_bi) as numar_bi
	from RU_persoane a 
	where ID_pers=@id_pers
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaPersoaneBI) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
