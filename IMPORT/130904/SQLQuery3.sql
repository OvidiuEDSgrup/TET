select * from sys.objects o where o.name like '%sp'
select * from webConfigTipuri t inner join sys.objects o on o.name=RTRIM(t.ProcDate)+'sp'
--o.name like 'yso_%'