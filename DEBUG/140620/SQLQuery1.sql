select * from istoricstocuri i where i.Cod='3135162321203' and i.Cod_gestiune='101' and i.Cod_intrare='17641' order by i.Data_lunii
select * from stocuri i where i.Cod='3135162321203' and i.Cod_gestiune='101' and i.Cod_intrare='17641' order by i.Data
select * from pozdoc p where p.Cod='3135162321203' and '101' in (p.Gestiune,p.Gestiune_primitoare) and '17641' in (p.Cod_intrare,p.Grupa) order by p.Data
--alter table pozdoc disable trigger all
--update pozdoc set Pret_de_stoc=1562.369352
--where idPozDoc=314941
--alter table pozdoc enable trigger all

--select top 100 * from sysspd p where p.Cod='3135162321203' order by p.Data_stergerii desc