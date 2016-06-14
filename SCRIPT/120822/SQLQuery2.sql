select * from pozdoc p where p.Tip='TE' and p.Cod_intrare=''
order by p.Data
select * from stocuri s where s.Cod like 'PKKP600/1200' and s.Cod_gestiune='211' --and s.Cod_intrare=''
select * from pozdoc p where p.Cod='PKKP600/1200' and p.Tip_miscare='E' and p.Cantitate<0 and p.Cod_intrare=''