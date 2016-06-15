--***
Create procedure wRUIaTinteIndicatori @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaTinteIndicatoriSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaTinteIndicatoriSP @sesiune, @parXML output
	return @returnValue
end

declare @utilizator char(10), @mesaj varchar(200), @id_indicator int
begin try
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select @id_indicator = isnull(@parXML.value('(row/@id_indicator)[1]','int'),0)

	select top 100 a.ID_tinta as id_tinta, a.ID_indicator as id_indicator, rtrim(a.Descriere) as descriere, 
		convert(char(10),a.Data_inceput,101) as data_inceput, convert(char(10),a.Data_sfarsit,101) as data_sfarsit, 
		convert(char(4),year(a.Data_sfarsit)) as an,  
		a.Interval_jos as interval_jos, a.Interval_sus as interval_sus, 
		rtrim(a.Valori) as valori, rtrim(a.Descriere_valori) as descr_valori,
		a.ID_calificativ as id_calificativ, c.Calificativ as calificativ, rtrim(c.Nivel_realizare) as nivel_realizare
	from RU_tinte_indicatori a 
		left outer join RU_indicatori b on a.ID_indicator=b.ID_indicator
		left outer join RU_calificative c on a.ID_calificativ=c.ID_calificativ
	where a.ID_indicator=@id_indicator
	order by Data_inceput desc	
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaTinteIndicatori) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
