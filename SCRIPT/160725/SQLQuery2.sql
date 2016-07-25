select *
from yso_DetTabInl d inner join yso_TabInl t on t.Tip=d.Tip and d.Camp_Magic=t.Denumire_SQL 
where t.Tip='4'

select * -- update t set t.numar_tabela=o.object_id
from yso_TabInl t join sys.objects o on o.name=t.Denumire_SQL 
--where 

select * from yso_DetTabInl d left join sys.objects o on o.name=d.Camp_Magic
where o.object_id is null

select (case when o.object_id is null then b.object_id else o.object_id end),
(case when o.name is null then b.name else o.name end)
,* -- update d set numar_tabela=(case when o.object_id is null then b.object_id else o.object_id end), camp_magic=(case when o.name is null then b.name else o.name end)
from yso_DetTabInl d left join sys.objects o on o.object_id=d.Numar_tabela
left join sys.objects b on b.name=d.Camp_Magic
--where o.name is null and b.object_id is null