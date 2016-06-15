--***
Create procedure wRUIaEvaluari @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaEvaluariSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaEvaluariSP @sesiune=@sesiune, @parXML=@parXML output
	return @returnValue
end

declare @utilizator char(10), @lista_evaluatori int, @mesaj varchar(200), @data_jos datetime, @data_sus datetime, @tip varchar(2), @id_evaluare int, @data datetime, 
	@f_persoana varchar(50), @f_nrfisa varchar(20)
select @lista_evaluatori=0	
begin try
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	select @lista_evaluatori=(case when Valoare<>'' then 1 else @lista_evaluatori end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='EVALUATOR'

	select @tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@id_evaluare = @parXML.value('(/row/@id_evaluare)[1]', 'int'),
		@data_jos = isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '01/01/1901'),
		@data_sus = isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '01/01/1901'), 
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@f_persoana = isnull(@parXML.value('(/row/@f_persoana)[1]', 'varchar(50)'), '%'),
		@f_nrfisa = isnull(@parXML.value('(/row/@f_nrfisa)[1]', 'varchar(20)'), '%')		

	select top 100 e.ID_evaluare as id_evaluare, rtrim(e.tip) as tip, 
	convert(char(10),e.Data,101) as data, rtrim(e.Numar_fisa) as nrfisa, 
	e.ID_evaluat as id_evaluat, rtrim(p.Nume) as denpers, 
	e.ID_evaluator as id_evaluator, rtrim(p1.Nume) as denevaluator, 
	e.An_evaluat as an_evaluat, convert(decimal(12,2),e.Media) as media, 
	e.ID_calificativ as id_calificativ, RTRIM(c.Nivel_realizare)+'('+rtrim(convert(char(4),c.Calificativ))+')' as dencalificativ
	from RU_evaluari e
		left outer join RU_persoane p on p.ID_pers= e.ID_evaluat
		left outer join RU_persoane p1 on p1.ID_pers= e.ID_evaluator
		left outer join RU_calificative c on c.ID_calificativ= e.ID_calificativ
		left outer join proprietati eu on eu.valoare=e.ID_evaluator and eu.tip='UTILIZATOR' and eu.cod=@utilizator and eu.cod_proprietate='EVALUATOR'
	where e.tip=@tip and (isnull(@id_evaluare,0)=0 or e.ID_evaluare=@id_evaluare)
		and (@data is not null and e.Data=@data or e.data between @data_jos and (case when @data_sus<='01/01/1901' then '12/31/2999' else @data_sus end))
		and (@f_persoana='%' or e.ID_evaluat like @f_persoana+'%' or p.Nume like '%'+@f_persoana+'%')
		and (@f_nrfisa='%' or e.Numar_fisa like @f_nrfisa+'%')
		and (e.Tip in ('OB')  or @lista_evaluatori=0 or eu.valoare is not null)
	order by e.ID_evaluare desc
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaEvaluari) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
