select p.Factura,p.Tert
from yso_LegComisionVanzari l join pozdoc p on p.idPozDoc=l.idPozDoc
group by p.Factura,p.Tert
having COUNT(distinct l.idPozDoc)>1

select * from pozdoc p where p.Numar_pozitie=542846