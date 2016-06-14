select * from efimpl e where e.Tert='RO17670277' order by data
select * from efecte e where e.Tert='RO17670277' order by data
select * from pozplin e where e.Tert='RO17670277' order by data
select * from extpozplin e inner join pozplin p on p.Subunitate=e.Subunitate
and p.Cont=e.Cont and p.Data=e.Data and p.Numar_pozitie=e.Numar_pozitie and p.Numar=e.Numar  
where p.Tert='RO17670277' order by p.data