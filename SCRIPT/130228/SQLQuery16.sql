select * from yso_DetTabInl d inner join yso_TabInl t on t.Tip=d.tip and t.Numar_tabela=d.Numar_tabela
where t.Denumire_SQL like 'proprietati%'

select * from yso_DetTabInl d where not exists (select Numar_tabela from yso_TabInl t where t.Tip=d.Tip and d.Numar_tabela=t.Numar_tabela)