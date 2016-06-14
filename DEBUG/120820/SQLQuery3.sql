select * from pozdoc p  where p.Tip='AP' and p.Cantitate<0 and p.Cod_intrare<>'' and p.Utilizator like 'MAG%' and p.Stare='3'
and not exists 
(select 1 from sysspd s where s.Subunitate=p.Subunitate and s.Tip=p.Tip and s.Numar=p.Numar and s.Data=p.Data
and s.Numar_pozitie=p.Numar_pozitie and s.Cod_intrare='')
order by p.Data

--/*
select * 
--*/delete p
from pozdoc p where p.Cod='PKKP600/600' and p.Gestiune='211' and p.Cod_intrare in ('5440005F','5440005G')
and p.Numar in 
('9310164' 
,'10003'   
,'10001'
)
--order by p.Data

select * from stocuri s where s.Cod_gestiune='211' and s.Cod='PKKP600/600'