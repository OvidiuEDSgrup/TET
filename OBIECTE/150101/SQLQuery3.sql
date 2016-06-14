--select * from par p where p.Parametru like '%fara%'
select top 1000 * from pozdoc p where p.Tip_miscare<>'V' order by p.idPozDoc desc