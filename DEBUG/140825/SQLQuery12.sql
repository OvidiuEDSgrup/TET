begin tran
delete p
from pozdoc p where p.Factura like 'CJ980788'
select t.Denumire,s.Locatie,* from stocuri s left join terti t on t.Subunitate=s.Subunitate and t.Tert=s.Locatie
where s.Cod_gestiune like '700.cj'
rollback tran