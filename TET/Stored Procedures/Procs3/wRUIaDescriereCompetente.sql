--***
/** procedura pentru citire descriere competente **/
Create procedure wRUIaDescriereCompetente @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaDescriereCompetenteSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaDescriereCompetenteSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @id_competenta int
begin try
	select @id_competenta = isnull(@parXML.value('(/row/@id_competenta)[1]','int'),0)
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select	top 100 rtrim(a.ID_desc_comp) as id_desc_comp, rtrim(a.ID_competenta) as id_competenta, 
		rtrim(a.tip_componenta) as tip_componenta, rtrim(a.componenta) as componenta, 
		convert(decimal(5,2),a.Procent) as procent, rtrim(a.descriere) as descriere, 
		(case when rtrim(a.tip_componenta)='1' then	'1-CUNOSTINTE' 
		else (case when rtrim(a.tip_componenta)='2' then '2-ABILITATI' else '3-COMPORTAMENTE' end) end) as desc_tip_componenta
	from RU_descriere_competente a where a.ID_competenta=@id_competenta
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaDescriereCompetente) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
