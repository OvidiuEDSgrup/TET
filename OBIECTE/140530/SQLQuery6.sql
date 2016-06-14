select * from pozdoc a
join doc d on d.Subunitate=a.Subunitate and d.Tip=a.Tip and d.Data=a.Data and d.Numar=a.Numar 
outer apply (select top 1 s=1 from pozdoc s join nomencl n on n.Cod=s.Cod
where s.Subunitate=a.Subunitate and s.Tip=a.Tip and s.Data=a.Data and s.Numar=a.Numar and n.Tip='s') s
where a.Subunitate='1' and a.Tip='AC'
and a.Data<='2014-05-23'
and s.s is not null and d.Valoare>0
order by a.idPozDoc desc