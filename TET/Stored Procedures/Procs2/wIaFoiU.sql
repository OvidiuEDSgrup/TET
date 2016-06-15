--***
CREATE procedure wIaFoiU @sesiune varchar(50), @parXML xml
as 
set transaction isolation level READ UNCOMMITTED
declare @eroare varchar(2000)
set @eroare=''
declare @userASiS varchar(10)

declare @datajos datetime, @datasus datetime, @tip varchar(2), @data datetime
begin try
	if object_id('tempdb.dbo.#luniAlfa')>0 drop table #luniAlfa
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	select	@datajos=dbo.bom(@parXML.value('(row/@datajos)[1]','datetime')),
			@datasus=dbo.eom(@parXML.value('(row/@datasus)[1]','datetime')),
			@data=dbo.eom(@parXML.value('(row/@data)[1]','datetime')),
			@tip=@parXML.value('(row/@tip)[1]','varchar(2)')

	select @datajos=isnull(@datajos,@data), @datasus=isnull(@datasus,@data)

	select c.luna, rtrim(max(c.LunaAlfa)) as lunaAlfa into #luniAlfa
	from calstd c 
	group by c.luna 
	order by c.luna

	select @tip tip, convert(varchar(20), data, 101) data, max(l.lunaAlfa)+' '+convert(varchar(4),year(data)) as etluna, 
			sum(isnull(reala,0)) as nrpozitii
	from
	(
		select max(dbo.eom(data)) as data, 1 as reala from activitati a
			where dbo.eom(data) between @datajos and @datasus and a.Tip='FL' and isnull(a.masina,'')<>''
		group by month(data), year(data), masina		--> pozitiile reale
		union all
		select dbo.eom(@datasus), 0 as reala			--> pozitie virtuala pentru ultima luna din interval (pentru adaugari)
	) x left join #luniAlfa l on month(x.data)=l.Luna
	group by data
	for xml raw
end try
begin catch
	set @eroare=ERROR_MESSAGE()
	if len(@eroare)>0
	set @eroare='wIaFoiU:'+
		char(10)+rtrim(@eroare)
end catch

if object_id('tempdb.dbo.#luniAlfa')>0 drop table #luniAlfa
if len(@eroare)>0 raiserror(@eroare,16,1)
