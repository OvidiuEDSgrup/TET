select * from bp left join antetbonuri a on bp.IdAntetBon=a.IdAntetBon
where bp.Casa_de_marcat=3 and bp.Data='2012-08-20' --and bp.Numar_bon=1

select p.Tert,* from pozdoc p where p.Tip in ('AP','AC') and p.Data='2012-08-20'
and (p.Utilizator like '%DJ' or p.Gestiune like '213%')