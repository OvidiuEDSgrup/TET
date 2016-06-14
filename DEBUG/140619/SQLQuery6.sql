SELECT * FROM pozdoc P where p.Cod='3135162321203' and '101' in (p.Gestiune,p.Gestiune_primitoare) and '17641' in (p.Cod_intrare,p.Grupa)
SELECT * FROM istoricstocuri P where p.Cod='3135162321203' and '101' in (p.Cod_gestiune) and '17641' in (p.Cod_intrare)
select top 100 * from syssp p where p.Denumire_parametru like '%inc%' order by p.Data_stergerii desc