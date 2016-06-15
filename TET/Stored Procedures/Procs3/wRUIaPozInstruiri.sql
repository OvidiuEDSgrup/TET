--***
Create procedure wRUIaPozInstruiri @sesiune varchar(50), @parXML XML
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaPozInstruiriSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaPozInstruiriSP @sesiune=@sesiune, @parXML=@parXML output
	return @returnValue
end

declare @utilizator char(10), @tip varchar(2), @id_instruire int, @doc xml, @mesaj varchar(200), @cautare varchar(500)
begin try
	select @tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@id_instruire=ISNULL(@parXML.value('(/row/@id_instruire)[1]','int'),0),
		@cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(500)'), '')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	select i.ID_instruire as id_instruire, rtrim(@tip) as tip, @tip as subtip, 'Instruire' as deninstruire, 
	i.ID_poz_instruire as id_poz_instruire, rtrim(i.ID_pers) as id_pers, rtrim(p.Nume) as denpers, 
	/*convert(char(10),i.Data_inceput,101) as data_inceput, convert(char(10),i.Data_sfarsit,101) as data_sfarsit,*/
	i.Durata as durata, convert(char(10),i.Data_absolvirii,101) as data_absolvirii, CONVERT(decimal(6,2),i.Nota) as nota, 
	RTRIM(i.Explicatii) as explicatii, RTRIM(i.Stare_pozitie) as starepozitie, (case when i.Stare_pozitie='A' then 'Absolvit' else 'Neabsolvit' end) as denstarepozitie,
	rtrim(i.Serie_diploma) as seriediploma, rtrim(i.Numar_diploma) as nrdiploma, rtrim(i.Eliberat_diploma) as elibdiploma, 
	convert(char(10),DATEADD(day,c.Periodicitate,i.Data_absolvirii),101) as data_curs_urm
	from RU_poz_instruiri i
		left outer join RU_instruiri ai on ai.ID_instruire=i.ID_instruire
		left outer join RU_persoane p on p.ID_pers=i.ID_pers
		left outer join RU_cursuri c on c.ID_curs=ai.ID_curs
	where i.ID_instruire=@id_instruire and (i.ID_pers like @cautare+'%' or p.Nume like '%'+@cautare+'%')
	order by i.ID_poz_instruire
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaPozInstruiri) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
