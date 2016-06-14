ALTER VIEW yso.pozconexp AS 
SELECT pozcon.*
	,ISNULL(pozconexp.Pret,0) as DiscDoi, ISNULL(pozconexp.Cantitate,0) as DiscTrei
	,(CASE pozcon.valuta WHEN '' THEN 1 ELSE 
		CASE con.curs WHEN 0 THEN (SELECT TOP 1 curs FROM curs WHERE Valuta=pozcon.valuta and data<=pozcon.data ORDER BY Data DESC) 
		ELSE con.curs END END) AS CursValuta
	,ISNULL(pozconexp2.Explicatii,'') AS Listare
	,ISNULL((SELECT SUM(Stoc) AS Cant_rezervata
		FROM dbo.stocuri s LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
		WHERE s.Subunitate=pozcon.subunitate and s.Tip_gestiune NOT IN ('F','T') and s.Contract=pozcon.Contract and s.Cod=pozcon.Cod
		AND (CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 AND s.Contract<>'' AND par.Val_logica=1) 
		AND s.Stoc>0.001) ,0) AS Cant_rezervata
FROM pozcon	
LEFT JOIN pozcon pozconexp ON pozconexp.Subunitate='EXPAND' and pozconexp.Tip=pozcon.Tip and pozconexp.Data=pozcon.Data 
	and pozconexp.Tert=pozcon.Tert and pozconexp.Contract=pozcon.Contract and pozconexp.Cod=pozcon.Cod and pozconexp.Numar_pozitie=pozcon.Numar_pozitie 
LEFT JOIN pozcon pozconexp2 ON pozconexp2.Subunitate='EXPAND2' and pozconexp2.Tip=pozcon.Tip and pozconexp2.Data=pozcon.Data 
	and pozconexp2.Tert=pozcon.Tert and pozconexp2.Contract=pozcon.Contract and pozconexp2.Cod=pozcon.Cod and pozconexp2.Numar_pozitie=pozcon.Numar_pozitie 
LEFT JOIN con ON con.Subunitate=pozcon.Subunitate and con.Tip=pozcon.Tip and con.Data=pozcon.Data and con.Tert=pozcon.Tert and con.Contract=pozcon.Contract
WHERE pozcon.Subunitate NOT LIKE 'EXPAND%' AND pozcon.Tip='BK'
GO
select * from yso.pozconexp where Contract='TEST'