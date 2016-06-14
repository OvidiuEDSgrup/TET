select * from yso_DetTabInl d 
where exists (select top 1 * from yso_TabInl t where d.Tip=t.Tip and d.Numar_tabela=t.Numar_tabela 
and
t.Denumire_SQL in
('docsters'                      
,'proprietati'                   
,'stoclim'))