select * from stocuri s where s.Cod='400018' and s.Stoc<0
select * from istoricstocuri p where p.Cod='400018' and 'S031400001799' in (p.Cod_intrare) and '101' in (p.Cod_gestiune)
order by p.Data_lunii, p.Data
select p.Gestiune_primitoare,p.Grupa,p.Cod_intrare,* from pozdoc p where p.Cod='400018' and 'S031400001799' in (p.Cod_intrare,p.Grupa) and '101' in (p.Gestiune,p.Gestiune_primitoare)
order by p.Data, p.Numar

select p.Gestiune_primitoare,p.Grupa,p.Cod_intrare,* from sysspd p where p.Cod='400018' and 'S031400001799' in (p.Cod_intrare,p.Grupa) and '101' in (p.Gestiune,p.Gestiune_primitoare)
order by p.Data, p.Numar, p.Data_stergerii desc

select p.Gestiune_primitoare,p.Grupa,p.Cod_intrare,* from pozdoc p where p.idPozDoc in 
(292287,821954)

select p.Gestiune_primitoare,p.Grupa,p.Cod_intrare,* from sysspd p where p.Numar in ('1140148')
order by p.Data_stergerii


select * from istoricstocuri i where i.Cod_intrare like 'S0%'