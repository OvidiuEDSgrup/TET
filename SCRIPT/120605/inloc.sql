select t.denumire_sql,d.* from dettabinl d left join tabinl t on d.tip=t.tip 
and d.numar_tabela=t.numar_tabela
where d.tip=1
order by t.denumire_sql

