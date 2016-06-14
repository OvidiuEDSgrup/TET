select * from pozdoc p 
where p.Tip='AP' and p.Cantitate<0 and p.detalii is not null
group by p.Numar
having count(
--order by p.idPozDoc desc