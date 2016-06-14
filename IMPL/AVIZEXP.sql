SELECT *
FROM pozdoc 
INNER JOIN yso.predariPacheteTmp pp ON pp.Subunitate=pozdoc.Subunitate AND pp.Numar=pozdoc.Numar AND pp.Data=pozdoc.Data 
INNER JOIN avnefac ON avnefac.Terminal=pp.Terminal AND avnefac.Subunitate=pozdoc.Subunitate AND avnefac.Tip='AP' 
	AND avnefac.Data=pp.DataAviz AND avnefac.Numar=pp.NumarAviz /*AND avnefac.Cod_gestiune='' AND avnefac.Contractul=''*/ 
INNER JOIN nomencl ON nomencl.Cod=pozdoc.Cod 
WHERE
pozdoc.subunitate=avnefac.subunitate 
and pozdoc.tip=avnefac.tip 
and pozdoc.numar=avnefac.numar 
and pozdoc.cod=nomencl.cod 
and pozdoc.subunitate=terti.subunitate 
and anexadoc.subunitate=avnefac.subunitate 
and anexadoc.tip=avnefac.tip 
and anexadoc.numar=avnefac.numar 
and anexadoc.data=avnefac.data 
and pozdoc.subunitate=doc.subunitate 
and pozdoc.tip=doc.tip 
and pozdoc.numar=doc.numar 
and pozdoc.subunitate=infotert.subunitate