select c from
(select c=1
union all
select 2
union all
select null
union all
select 2) t
group by c