select p.Tert,* from pozdoc p where p.Cod='067224'
and p.Cod_intrare='1141204005'
order by p.Data

select * from pozcon p where p.Factura='101' and p.Cant_aprobata<0
order by p.idPozCon desc