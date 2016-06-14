select * -- update c set cod_vechi=cod_nou, cod_nou=cod_vechi 
from yso_CodInl c
insert yso_TabInl 
(Tip,Numar_tabela,Denumire_magic,Denumire_SQL,Camp1,Camp2,Inlocuiesc)
select -1,Numar_tabela,Denumire_magic,Denumire_SQL,Camp1,Camp2,Inlocuiesc 
from yso_TabInl t where t.Denumire_SQL in
('docsters'                      
,'proprietati'                   
,'stoclim') and t.Tip=-11

insert yso_DetTabInl
(Tip,Numar_tabela,Camp_Magic,Camp_SQL,Conditie_de_inlocuire)
select -1,d.Numar_tabela,Camp_Magic,Camp_SQL,Conditie_de_inlocuire
from yso_TabInl t join yso_DetTabInl d on d.Tip=t.Tip and d.Numar_tabela=t.Numar_tabela where t.Denumire_SQL in
('docsters'                      
,'proprietati'                   
,'stoclim') and t.Tip=-11

insert yso_TabInl 
(Tip,Numar_tabela,Denumire_magic,Denumire_SQL,Camp1,Camp2,Inlocuiesc)
select -tip,Numar_tabela,Denumire_magic,Denumire_SQL,Camp1,Camp2,'Da' 
from yso_TabInl t where t.Tip=1

insert yso_DetTabInl
(Tip,Numar_tabela,Camp_Magic,Camp_SQL,Conditie_de_inlocuire)
select -d.Tip,d.Numar_tabela,Camp_Magic,Camp_SQL,Conditie_de_inlocuire
from yso_TabInl t join yso_DetTabInl d on d.Tip=t.Tip and d.Numar_tabela=t.Numar_tabela where t.Tip=1

select distinct v.Denumire_SQL from yso_TabInl v join sys.tables s on s.name=v.Denumire_SQL
where v.Denumire_SQL not in
(select Denumire_SQL 
from yso_TabInl t 
where 
--t.Denumire_SQL like 'proprietati'
t.Tip=1)
and exists 
(select 1 from sys.columns c where c.object_id=s.object_id and c.name like 'cod%')