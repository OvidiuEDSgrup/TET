--select * from pozdoc p where p.Numar like '10001' and p.Data='2012-04-05' and p.Cod='PKTER151HP20SLOX1C_1'

--select * from Bonuri b where b.Numar_bon=6 and b.Data='2012-04-27' and b.Casa_de_marcat=1 --and b.Cod_produs='PKTER151HP20SLOX1C_1'
select * from antetBonuri b where b.Data_bon='2012-04-07' and b.Casa_de_marcat=1 and b.Numar_bon=2