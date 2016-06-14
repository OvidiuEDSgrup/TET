FROM pozdoc INNER JOIN nomencl ON nomencl.Cod=pozdoc.Cod LEFT JOIN lm on pozdoc.Loc_de_munca=lm.cod 
INNER JOIN TERTI ON POZDOC.TERT=TERTI.TERT 
INNER JOIN DOC ON POZDOC.NUMAR=DOC.NUMAR and doc.tip='TE'  and pozdoc.data=doc.data and pozdoc.gestiune=doc.cod_gestiune 
INNER JOIN INFOTERT on pozdoc.tert=infotert.tert 
INNER JOIN AVNEFAC ON POZDOC.SUBUNITATE=AVNEFAC.SUBUNITATE     
INNER JOIN con on con.Subunitate=pozdoc.Subunitate and con.Tip='BK'  and con.tert=pozdoc.tert