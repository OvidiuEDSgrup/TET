select top 10 p.Gestiune,p.Cod_intrare,p.Gestiune_primitoare,p.Grupa,* -- delete p 
from pozdoc p where p.Subunitate='1' and p.Tip='te' and p.Utilizator='ASIS' and (p.Cantitate<0 and p.Data='2012-11-23' or p.Numar='12')
--order by p.idPozDoc desc

select * from stocuri s where s.Cod_gestiune='700' and s.Stoc>0
select * from stocuri s where s.Cod_gestiune='212' and s.Comanda='1710605126190' 
and s.Stoc>0 and s.Cod in
('18075CUI2X20        '
,'19PK-1605           '
,'5090 028000000      ')