select *
--delete p
from pozdoc p inner join yso_rapVerificareDescarcareBonTblRez1 r
on r.nrpozdoc=p.Numar and p.Tip='AC' and p.Cod=r.cod
where p.Data between '2012-08-01' and '2012-08-31'