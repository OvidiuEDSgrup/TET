select * from sysspcon s left join pozcon p on p.Subunitate=s.Subunitate and p.Tip=s.Tip and p.Contract=s.Contract
and p.Tert=s.Tert and p.Data=s.Data and p.Numar_pozitie=s.Numar_pozitie
where s.Contract='9810615' and s.Cant_aprobata<>p.Cant_aprobata
order by s.Data_stergerii desc