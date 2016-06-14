select p.Tert,* from pozdoc p where p.Tip_miscare='E' and p.Gestiune like '%sv' and p.Cod='41010091EX' 
--tert='RO18626210   '
order by p.idPozDoc desc
--p.numar like 'SV940253'
SELECT * from yso.predariPacheteTmp p where p.Terminal='6180'

select * from con c where c.Contract =''