CREATE PROC yso_predariPachete @cHostId char(25) AS 
EXEC yso.predariPachete @cHostId=@cHostId

--EXEC yso.predariPachete '11140'
--select * from #codIntrarePachete
--select p.* from pozdoc p join nomencl n on p.cod=n.cod where n.tip='P' and p.tip in ('te','ap') 
--and p.cod='PKHM101TF_09' 
--select * from yso.predariPacheteTmp  where terminal=@CHOSTID

--select * 
--FROM pozdoc INNER JOIN yso.predariPacheteTmp pp ON pp.Subunitate=pozdoc.Subunitate AND pp.tip=pozdoc.tip AND pp.Numar=pozdoc.Numar 
--	AND pp.Data=pozdoc.Data and pp.numar_pozitie=pozdoc.numar_pozitie INNER JOIN avnefac ON avnefac.Terminal=pp.Terminal AND avnefac.Subunitate=pozdoc.Subunitate AND avnefac.Tip='AP' AND avnefac.Data=pp.DataAviz AND avnefac.Numar=pp.NumarAviz /*AND avnefac.Cod_gestiune='' AND avnefac.Contractul=''*/ INNER JOIN nomencl ON nomencl.Cod=pozdoc.Cod
--WHERE 1=1 and avnefac.Terminal=@CHOSTID