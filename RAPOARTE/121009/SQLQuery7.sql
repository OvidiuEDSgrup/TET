select p.Accize_cumparare,* from pozdoc p inner join nomencl n on n.Cod=p.Cod
where p.Cod like 'PKKP600/1200        '
and p.Data between '2012-08-01' and '2012-08-31'
and p.Loc_de_munca='1MKT19' and p.Tert='RO16117601' and n.Grupa='A031' order by p.Cod,p.Cod_intrare