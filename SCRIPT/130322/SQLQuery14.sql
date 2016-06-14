select * from pozcon p left join tet..pozcon c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract
and c.Tert=p.Tert and c.Cod=p.Cod
where p.Contract='9820957' 
and c.Numar_pozitie is null