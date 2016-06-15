create view tbani as
SELECT { fn YEAR(pozplin.Data) } AS Anul, 
    { fn MONTH(pozplin.Data) } AS Luna, 
    pozplin.Data AS zi, LEFT(pozplin.Plata_incasare, 1) 
    AS PI, conturi.Denumire_cont, ISNULL(terti.Denumire, 
    'Fara tert') AS Partener, ISNULL(lm.Denumire, '') 
    AS Locmunca, pozplin.Suma
FROM pozplin INNER JOIN
    conturi ON 
    pozplin.Cont = conturi.Cont LEFT OUTER JOIN
    terti ON pozplin.Tert = terti.Tert LEFT OUTER JOIN
    lm ON pozplin.Loc_de_munca = lm.Cod
WHERE (pozplin.Cont LIKE '5%')