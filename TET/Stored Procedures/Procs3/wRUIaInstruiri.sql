--***
Create procedure wRUIaInstruiri @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaInstruiriSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaInstruiriSP @sesiune=@sesiune, @parXML=@parXML output
	return @returnValue
end

declare @sub varchar(9), @utilizator char(10), @mesaj varchar(200), @data_jos datetime, @data_sus datetime, @tip varchar(2), @id_instruire int, @data datetime, 
	@f_nrfisa varchar(20), @f_curs varchar(100), @f_tiptrainer varchar(50), @f_trainer varchar(50), @f_stare varchar(20)
begin try
	set @sub=dbo.iauParA('GE','SUBPRO')
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	select @tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@id_instruire = @parXML.value('(/row/@id_instruire)[1]', 'int'),
		@data_jos = isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '01/01/1901'),
		@data_sus = isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '01/01/1901'), 
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@f_nrfisa = isnull(@parXML.value('(/row/@f_nrfisa)[1]', 'varchar(20)'), '%'),
		@f_curs = isnull(@parXML.value('(/row/@f_curs)[1]', 'varchar(100)'), '%'),
		@f_tiptrainer = isnull(@parXML.value('(/row/@f_tiptrainer)[1]', 'varchar(50)'), '%'),
		@f_trainer = isnull(@parXML.value('(/row/@f_trainer)[1]', 'varchar(50)'), '%'),
		@f_stare = isnull(@parXML.value('(/row/@f_stare)[1]', 'varchar(20)'), '%')
		set @data_sus=(case when @data_sus<='01/01/1901' then '12/31/2999' else @data_sus end)
				
	select top 100 i.ID_instruire as id_instruire, @tip as tip, convert(char(10),i.Data,101) as data, rtrim(i.Numar_fisa) as nrfisa, 
	convert(char(10),i.Data_inceput,101) as data_inceput, convert(char(10),i.Data_sfarsit,101) as data_sfarsit, i.ID_curs as id_curs, rtrim(c.Denumire) as dencurs,
	rtrim(i.Tematica) as tematica, rtrim(i.Tip_trainer) as tiptrainer, (case when i.Tip_trainer='F' then 'Firma' else 'Angajat' end) as dentiptrainer, 
	rtrim(i.Trainer) as trainer, rtrim((case when i.Tip_trainer='F' then t.Denumire else p.Nume end)) as dentrainer, 
	rtrim(i.Tip_locatie) as tiplocatie, (case when i.Tip_locatie='L' then 'Loc de munca' else 'Tert' end) as dentiplocatie, 
	rtrim(i.Locatie) as locatie, rtrim((case when i.Tip_locatie='L' then lm.Denumire else l.Denumire end)) as denlocatie, 
	rtrim(i.Stare) as stare, (case when i.Stare='P' then 'Programat' when i.Stare='A' then 'Anulat' when i.Stare='D' then 'Desfasurare' when i.Stare='F' then 'Finalizat' end) as denstare,
	rtrim(i.Comanda) as comanda, rtrim(z.Descriere) as dencomanda
	from RU_instruiri i
		left outer join terti t on t.Subunitate=@sub and t.Tert= i.Trainer
		left outer join terti l on l.Subunitate=@sub and l.Tert= i.Locatie
		left outer join personal p on p.Marca=i.Trainer
		left outer join RU_cursuri c on c.ID_curs= i.ID_curs
		left outer join lm on lm.Cod=i.Locatie
		left outer join Comenzi z on z.Subunitate=@sub and z.Comanda=i.Comanda
	where (isnull(@id_instruire,0)=0 or i.ID_instruire=@id_instruire)
		and (@data is not null and i.Data=@data or i.data between @data_jos and @data_sus or i.Data_inceput between @data_jos and @data_sus or i.Data_sfarsit between @data_jos and @data_sus)
		and (@f_nrfisa='%' or i.Numar_fisa like @f_nrfisa+'%')
		and (@f_curs='%' or i.id_curs like @f_curs+'%' or c.Denumire like '%'+rtrim(@f_curs)+'%')
		and (@f_tiptrainer='%' or i.Tip_trainer=@f_tiptrainer)
		and (@f_trainer='%' or i.Trainer like @f_trainer+'%' or t.Denumire like '%'+rtrim(@f_trainer)+'%' or p.Nume like '%'+rtrim(@f_trainer)+'%')
		and (@f_stare='%' or i.Stare like @f_stare+'%')
	order by i.ID_instruire desc
	for xml raw

end try

begin catch
	set @mesaj = '(wRUIaInstruiri) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
