select t.Denumire_SQL,d.Camp_SQL, so.object_id, sc.column_id, d.Conditie_de_inlocuire
from DetTabInl d join TabInl t on t.Tip=d.Tip and t.Numar_tabela=d.Numar_tabela
join [sys].[objects] so on so.name=t.Denumire_SQL 
join [sys].[columns] sc on sc.object_id=so.object_id and sc.name= d.Camp_SQL
where t.Tip=1 and so.type='U' and sc.system_type_id IN (167,175) and sc.MAX_length>20 
and t.Inlocuiesc='da'
select * from TabInl
