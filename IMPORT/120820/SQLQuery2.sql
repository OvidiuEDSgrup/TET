select * from pozdoc p where p.Cod not in (select n.cod from nomencl n)
and p.Tip<>'rp'