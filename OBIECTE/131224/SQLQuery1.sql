select p.Stare,* from sysspd p where p.Numar='9841332'
--alter table pozdoc disable trigger all
select p.Stare,p.Discount,* -- update p set stare=2
from pozdoc p where p.Numar='9841332'
select p.Stare,* -- update p set stare=2
from doc p where p.Numar='9841332'
--alter table pozdoc enable trigger all