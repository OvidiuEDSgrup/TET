select top (10) * 
from pozdoc p where p.Tip='TE' and p.Cantitate=1
order by p.idPozDoc desc

select * from DocDeContat d where d.tip='TE'