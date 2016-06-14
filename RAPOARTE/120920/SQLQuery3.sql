select * from bp left join antetbonuri a on a.idantetbon=bp.IdAntetBon 
where a.Gestiune='211.1' and bp.Data='2012-08-22'
select * from pozdoc p where p.Tip IN ('AC','TE') and p.Data='2012-08-02' and p.Cod like 'AVANS'