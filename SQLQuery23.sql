select * from pozdoc p where p.Numar like '9410123%' or p.Factura like '9410123%'
select * from pozdoc p where p.Numar like '10002' and p.Data = '04/30/2012'
select * from antetBonuri a where a.Casa_de_marcat=1 and a.Numar_bon=2 and a.Data_bon='2012-04-30'