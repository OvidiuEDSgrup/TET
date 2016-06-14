select * from pozcon p where p.Contract='9821352'
select * --delete p
from pozdoc p where p.Factura='9821352'
select * from sysspcon p where p.Contract='9821352' order by p.data_stergerii desc


--select * from pozdoc p 
--where p.Utilizator='magazin_cj'
--order by p.Data_operarii desc, p.Ora_operarii desc