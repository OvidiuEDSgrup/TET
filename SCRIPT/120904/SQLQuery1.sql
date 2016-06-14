select p.Tert,* from pozdoc p where p.factura='115759'
select * from facturi f where f.Factura='115759'
--select * from extpozplin e 
select * from pozplin p where p.Factura='115759'
--alter table facturi enable trigger yso_tr_validfacturi