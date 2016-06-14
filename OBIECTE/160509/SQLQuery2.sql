select * from istfact i where i.Factura like 'NT941882'
select * 
from par p where tip_parametru='GE' and parametru in ('ANULINC','LUNAINC')

select * from pozdoc p where p.Numar_pozitie in (
204788,
204789,
204790
)

select * from pozdoc p where p.Numar like 'NT941882'