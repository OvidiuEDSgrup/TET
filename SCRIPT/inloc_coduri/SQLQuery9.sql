select n.Tip,n.Denumire,* from pozdoc p  join nomencl n on n.Cod=p.Cod 
where p.Tip='RM' and n.Tip in ('R','S')