SELECT * from pozdoc p where p.Tip in ('AP','AE','AC') and p.Cod_intrare='' and exists 
(select 1 from stocuri s where s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Data<=p.Data
and s.Stoc>0.001 and abs(s.Pret-p.Pret_de_stoc)<0.009)