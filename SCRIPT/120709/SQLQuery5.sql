select * from pozdoc p where p.Factura='119070'
select * from pozincon i where i.Data='2012-07-06'
and i.Tip_document='ap' and i.Numar_document='119070'
select distinct p.Cont_venituri from pozdoc p where p.Tip='ap'