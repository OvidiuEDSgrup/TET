begin tran
exec wDescarcBon '','<row idAntetBon="2457" />'
select * -- delete p
from pozdoc p where p.Subunitate='1' and p.Tip in ('AC','te') and p.Cantitate<=-0.001
--and p.Pret_de_stoc=p.Pret_vanzare 
and p.Numar='20001' AND P.Data='2013-06-22'
rollback tran