--select * from pozdoc p where p.Tip in ('AP','AC')
select n.Denumire,s.* from stocuri s join nomencl n on n.Cod=s.cod
where s.Cod_gestiune in ('211','212')
and s.cod not in 
(select pr.cod_produs from preturi pr where pr.UM=4)