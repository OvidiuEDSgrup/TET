--***
CREATE procedure wIaPozFoiU @sesiune varchar(50), @parXML xml
as 
set transaction isolation level READ UNCOMMITTED
declare @eroare varchar(2000)
, @cautare varchar(500)

set @eroare=''
declare @userASiS varchar(10)

if object_id('tempdb..#tmp') is not null drop table #tmp

declare @data_lunii datetime, @tip varchar(2)
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	select	@data_lunii=@parXML.value('(row/@data)[1]','datetime'),
			@tip=@parXML.value('(row/@tip)[1]','varchar(2)')
			,@cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(500)'), '')
			
	declare @elemOre varchar(30)
	set @elemOre='OL'
	select	rtrim(max(m.denumire)) as etMasina, --convert(varchar(20),@data_lunii,101) as etData,
			rtrim(a.Masina) as masina, --convert(varchar(20),a.Data,101) data, 
			'FU' as subtip,
			@data_lunii as data, @tip as tip,
			(select convert(decimal(20,2),sum(ea.Valoare)) from elemactivitati ea 
				inner join activitati a1 on ea.fisa=a1.fisa and ea.data=a1.data
			where a1.Masina=a.Masina and a1.tip='FL' and month(a1.Data)=month(@data_lunii) and year(a1.Data)=year(@data_lunii) and
					ea.Element=@elemOre)
				as OL,
		max(t.Tip_activitate) Tip_activitate, max(a.idActivitati) idActivitati
	into #tmp
	from activitati a left join masini m on a.Masina=m.cod_masina
		left outer join grupemasini g on g.grupa=m.grupa
		left join tipmasini t on g.tip_masina=t.Cod
	where a.tip='FL' and month(a.Data)=month(@data_lunii) and year(a.Data)=year(@data_lunii)
		and isnull(a.masina,'')<>''
	and isnull(m.Denumire,'') like '%'+@cautare+'%'
	group by a.masina
	order by a.masina --convert(varchar(20),a.Data,101)
	
	select row_number() over (partition by ea.element, a.masina order by ea.Data desc, ea.Fisa desc, ea.Numar_pozitie desc) as ordine,
		ea.element, a.masina, valoare, m.Tip_activitate
	into #elemact
	from elemactivitati ea
		inner join activitati a on a.Tip=ea.Tip and a.Fisa=ea.Fisa and a.Data=ea.Data 
		inner join #tmp m on a.Masina=m.masina
	where
	ea.Element in ('KmBord','OREBORD')
		
	select t.etMasina, t.masina, t.subtip, t.data, t.tip, t.OL, ea.kmore, t.idActivitati
	from #tmp t
		left join (select ea.Masina, ltrim(str(
						sum(case when ea.Tip_activitate='P' and ea.element='KmBord' or 
									ea.Tip_activitate='L' and ea.element='OREBORD' then ea.Valoare else '' end),12,2)) as kmore
					from #elemact ea where ea.ordine=1 group by ea.masina) ea on t.masina=ea.Masina
	for xml raw
end try
begin catch
	set @eroare=ERROR_MESSAGE()
	if len(@eroare)>0
	set @eroare='wIaPozFoiU:'+
		char(10)+rtrim(@eroare)
end catch

if object_id('tempdb..#tmp') is not null drop table #tmp

if len(@eroare)>0 raiserror(@eroare,16,1)
