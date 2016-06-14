select * from pozcon p inner join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert
where p.Contract= '9820675'
order by p.Numar_pozitie