begin tran
--select *
select s.Locatie,* from stocuri s where s.Cod_gestiune='700.sv' 
delete p
from pozdoc p where p.Subunitate='1' and p.Tip='TE' and p.Numar='TEST3' and p.Cantitate<0
select s.Locatie,* from stocuri s where s.Cod_gestiune='700.sv' 
rollback tran