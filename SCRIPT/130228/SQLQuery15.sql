select t.Denumire,* from infotert i inner join terti t on t.Tert=i.Tert
where i.Loc_munca <>'' and i.Loc_munca not in 
(select cod from lm)