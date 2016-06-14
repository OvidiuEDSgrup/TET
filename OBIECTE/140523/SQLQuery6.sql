select top 10 * from pozdoc p join nomencl n on n.Cod=p.Cod
where n.Denumire like '%asist%'
order by p.idPozDoc desc