select * from pozincon p where p.Loc_de_munca not in 
(select cod from lm)
select distinct p.Loc_de_munca from pozdoc p where p.Loc_de_munca not in 
(select cod from lm)