SELECT *
FROM pozdoc INNER JOIN yso.predariPacheteTmp pp ON pp.Subunitate=pozdoc.Subunitate AND pp.tip=pozdoc.tip AND pp.Numar=pozdoc.Numar AND pp.Data=pozdoc.Data and pp.numar_pozitie=pozdoc.numar_pozitie 
INNER JOIN avnefac ON avnefac.Terminal=pp.Terminal AND avnefac.Subunitate=pozdoc.Subunitate AND avnefac.Tip='AP' AND avnefac.Data=pp.DataAviz AND avnefac.Numar=pp.NumarAviz /*AND avnefac.Cod_gestiune='' AND avnefac.Contractul=''*/ INNER JOIN nomencl ON nomencl.Cod=pozdoc.Cod 
LEFT JOIN con on con.Subunitate=pozdoc.Subunitate and con.Tip='BK' and con.Contract=pp.Contract 
LEFT JOIN pozcon on pozcon.Subunitate=con.Subunitate and pozcon.Tip=con.Tip and pozcon.Contract=con.Contract and pozcon.Cod=pp.CodPachet 
LEFT JOIN lm on pozdoc.Loc_de_munca=lm.cod 