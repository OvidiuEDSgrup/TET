--insert TabInl
select Tip=-5,Numar_tabela=t.Numar_tabela,Denumire_magic=t.Denumire_magic,Denumire_SQL=t.Denumire_SQL,Camp1=t.Camp1,Camp2=t.Camp2
	,Inlocuiesc=t.Inlocuiesc
	-- delete t
from TabInl t inner join sys.objects o on o.name=t.Denumire_SQL
where t.Tip=5 --and t.Numar_tabela=37


-- delete DetTabInl where tip=-2 insert DetTabInl
select Tip=-2,Numar_tabela=t.Numar_tabela,Camp_Magic=t.Denumire_magic,Camp_SQL=d.Camp_SQL,Conditie_de_inlocuire=d.Conditie_de_inlocuire
	-- delete t
from TabInl t 
	inner join detTabInl d on d.Tip=t.Tip and d.Numar_tabela=t.Numar_tabela 
	inner join sys.objects o on o.name=t.Denumire_SQL
where t.Tip=2 --and t.Numar_tabela=37

select *
--into yso_DetTabInl
from DetTabInl