select * from testov..rulaje r where r.Data between '2012-01-01' and '2012-01-31'
except
select * from tet..rulaje r where r.Data between '2012-01-01' and '2012-01-31'
--insert tet..yso_CodInl (Tip,Cod_vechi,Cod_nou)
select * from yso_CodInl
select * from yso_DetTabInl d inner join yso_TabInl t on t.Numar_tabela=d.Numar_tabela and d.Tip=t.Tip
where t.Tip=-11 and d.Camp_SQL not like '%gest%' and t.Inlocuiesc='Da'
--and not exists (select 1 from yso_DetTabInl d1 where d1.Tip=d.Tip and d.Numar_tabela=d1.Numar_tabela and d.Camp_SQL like '%gest%')

