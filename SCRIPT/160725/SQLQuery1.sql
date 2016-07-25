
select * -- delete t
from yso_TabInl t where t.Tip in (4) --and t.Denumire_SQL not in 

insert into yso_TabInl (Tip,Numar_tabela,Denumire_magic,Denumire_SQL,Camp1,Camp2,Inlocuiesc)
select Tip,Numar_tabela,Denumire_magic,Denumire_SQL,Camp1,Camp2,Inlocuiesc
from TabInl t where t.Tip in (4)
