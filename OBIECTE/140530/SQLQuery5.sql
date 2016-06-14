SELECT n.Tip,* 
FROM pozdoc p 
join nomencl n on n.Cod=p.Cod
where p.Data='2014-04-15' 
and p.Tip='AC' 
--and p.Cantitate>0
--AND n.Tip='s'
--AND EXISTS (select top 1 * from pozdoc d where d.Subunitate=p.Subunitate and d.Tip=p.Tip and d.Numar=p.Numar and d.Data=p.Data and d.idPozDoc<>p.idPozDoc and d.Cantitate>0) 
--and p.Cod='AVANS'
and p.Numar='GL70003 '
order by p.idPozDoc desc