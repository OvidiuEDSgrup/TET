--***
create procedure [dbo].[rapbuget] 
--declare
@codi char(20),@dataj datetime,@datas datetime,@el1 char(30)
as
--
begin
set transaction isolation level read uncommitted
exec calculind @codi,@dataj,@datas
declare @exista int,@nivel int

--set @codi='BUGET'

create table #ind(codi char(13),nivel int,parinte char(13))
insert into #ind values(@codi,0,'')

set @nivel=0
set @exista=1
while @exista>0
begin
 insert into #ind
 select fiu,@nivel+1,parinte from compind where parinte in 
 (select codi from #ind where nivel=@nivel)
 set @exista=@@rowcount
 set @nivel=@nivel+1
end

select i.expresie,c.lunaalfa,c.luna,i.cod_indicator,i.denumire_indicator,e.data,e.element_1,e.element_2,
	e.element_3,e.element_4,e.element_5,
	(case when e.tip='E' then e.valoare else 0 end) as 'Valoare',
	(case when e.tip='P' then e.valoare else 0 end) as 'Previzionat',
	#ind.parinte as parinte,#ind.nivel as nivel
from indicatori i
	left outer join expval e on i.cod_indicator=e.cod_indicator and (@el1 is null or e.element_1=@el1)
		and data between @dataJ and @dataS
	full join calstd c on isnull(e.data,'01/01/2005')=c.data
	full outer join #ind on #ind.codi=i.cod_indicator
where exists (select 1 from #ind where i.cod_indicator=#ind.codi )
	--	and i.Ordine_in_raport<>0	--> Luci Maier:	ar trebui vazut ce e cu procedura asta (daca raportul apelant are sens) si apoi optimizata/regandita un pic
order by #ind.nivel

drop table #ind
end
