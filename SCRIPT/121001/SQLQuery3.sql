select p.Data_operarii,* from pozdoc p where p.Cod like '100-ISO4-R16-RO' 
and p.Data between '2012-08-01' and '2012-08-31'
--and p.Data_operarii>='2012-09-10'
order by p.Data_operarii desc

select * from inventar i
where i.Data_inventarului='2012-08-31'
and i.Cod_produs='100-ISO4-R16-RO    '
