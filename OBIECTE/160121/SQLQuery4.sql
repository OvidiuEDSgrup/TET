select * from webconfigform f where f.Tip like 'rs' and f.DataField like '%dvi%'

select * from webconfiggrid f where f.Tip like 'rs' and f.DataField like '%dvi%'

select Factura,* from pozdoc p where p.Data>='2015-01-01' and p.Cont_de_stoc like '622%' and p.Tip_miscare like 'V'
ORder by p.idPozDoc desc