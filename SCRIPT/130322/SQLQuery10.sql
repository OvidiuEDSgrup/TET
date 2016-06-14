select *
from pozadoc p left join dvi d on  p.Factura_dreapta=d.Factura_CIF
inner join terti t on t.tert=p.tert
where 
p.Data between '2013-01-01' and '2013-01-31'
and p.Cont_cred like '401.7%'

select *
from pozdoc p left join dvi d on  p.Factura=d.Factura_CIF
inner join terti t on t.tert=p.tert
where  p.tip in ('RM','RS')
and p.Data between '2013-01-01' and '2013-01-31'
and p.Cont_factura like '401.7%'

select *
from pozincon where Tip_document in ('RM','RS')  and Numar_document='6132'  and Cont_creditor='4427'