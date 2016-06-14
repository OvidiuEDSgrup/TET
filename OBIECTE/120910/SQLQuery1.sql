declare @cant float, @cod varchar(20)

select @cod='A',@cant=1
into #pozdocstoc
union all select 'B',3
union all select 'C',5
--union all select 'A',2



update #pozdocstoc
set @cant=cant+1, cant=@cant
where cod='A'

select @cant
select * from #pozdocstoc

drop table #pozdocstoc