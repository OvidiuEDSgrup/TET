select * from (SELECT     p.Contract, p.Cod, sum(p.cantitate-p.Cant_realizata) as Cantitate, n.Furnizor, t.Denumire AS denFurnizor, c.Gestiune, n.Denumire, n.UM, ISNULL
                          ((SELECT     SUM(Stoc) AS Expr1
                              FROM         stocuri
                              WHERE     (Cod = p.Cod) AND (Cod_gestiune = c.Gestiune)), 0) AS stoc,
                              (select Denumire from terti where tert=max(p.Tert)) as tert
FROM         pozcon AS p INNER JOIN
                      con AS c ON p.Tip = c.Tip AND p.Contract = c.Contract AND p.Tert = c.Tert INNER JOIN
                      nomencl AS n ON p.Cod = n.Cod INNER JOIN
                      terti AS t ON n.Furnizor = t.Tert
WHERE     p.Data>=@data1 AND p.Data<=@data2
 and (isnull(@cod, '') = '' OR  p.cod= rtrim(rtrim(@cod)))
  and (isnull(@gestiune, '') = '' OR  c.Gestiune= rtrim(rtrim(@gestiune)))
   and (isnull(@furnizor, '') = '' OR  n.Furnizor= rtrim(rtrim(@furnizor)))
and p.um='1'
and (isnull(@stare, '') = '' OR  c.stare= rtrim(rtrim(@stare)))

   group by p.Contract,p.Cod,n.Furnizor,t.Denumire,c.Gestiune,n.Denumire,n.UM
   )r
   where r.Cantitate>r.stoc
   order by r.Denumire