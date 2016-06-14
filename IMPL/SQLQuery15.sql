select * from infotert i
where i.Subunitate='1' and i.Identificator='' and i.Loc_munca not in 
(select l.cod from lm l)

