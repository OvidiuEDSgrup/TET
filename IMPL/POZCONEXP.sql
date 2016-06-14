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
		AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 
		AND s.Stoc>0.001) ,0) AS Cant_rezervata
	
	,isnull((select sum(cant_comandata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=pozcon.contract 
	and pa.data_comenzii=pozcon.data and pa.beneficiar=pozcon.tert and pa.cod=pozcon.cod /*and abs(pa.cant_realizata)<0.001*/),0) Cant_comandata
	
	,ISNULL((SELECT SUM(Stoc)
		FROM dbo.stocuri s 
		WHERE s.Subunitate=pozcon.Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 AND pozcon.Cod=s.Cod
			AND (s.Cod_gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND s.Contract=pozcon.Contract
				OR s.Cod_gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND s.Contract=''
				OR CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 AND s.Contract=''
				OR s.Contract=pozcon.Contract)),0) AS Cant_stoc_gest
	
	,ISNULL(REPLACE(REPLACE((select REPLACE(rtrim(CONVERT(varchar,SUM(p.cantitate)))+'_'+rtrim(isnull(nomencl.UM,'')) 
		+'_cu_'+RTRIM(p.Tip)+'_'+rtrim(p.numar)+'_din_'+rtrim(convert(varchar,p.data,102)),' ','_') 
		from stocuri s left join pozdoc p on p.Subunitate=s.Subunitate and p.Tip='TE' and p.Factura=s.Contract and p.Gestiune_primitoare=s.Cod_gestiune 
			and p.Cod=s.cod and p.Grupa=s.Cod_intrare and p.stare not in ('4', '6') and p.cantitate>0 
		WHERE s.Tip_gestiune NOT IN ('F','T') and s.Contract=pozcon.Contract AND s.Cod=pozcon.Cod AND s.Stoc>0.001
			AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 
		GROUP BY p.Tip,p.Numar,p.Data FOR XML PATH('')),' ','_'),'_',' '),'') AS Rezervari
	
	,ISNULL(REPLACE(REPLACE((select REPLACE(rtrim(CONVERT(varchar,SUM(p.cantitate)))+'_'+rtrim(isnull(max(n.UM),'')) 
		+'_cu_'+RTRIM(p.Tip)+'_'+rtrim(p.numar)+'_din_'+rtrim(convert(varchar,p.data,102)),' ','_') 
		from stocuri s left join pozdoc p on p.Subunitate=s.Subunitate and p.Tip='AP' and p.Contract=s.Contract and p.Gestiune=s.Cod_gestiune 
			and p.Cod=s.cod and p.Cod_intrare=s.Cod_intrare and p.cantitate>0 
		where 
		GROUP BY p.Tip,p.Numar,p.Data FOR XML PATH('')),' ',';'),'_',' '),'')
FROM pozcon	
LEFT JOIN pozcon pozconexp ON pozconexp.Subunitate='EXPAND' and pozconexp.Tip=pozcon.Tip and pozconexp.Data=pozcon.Data 
	and pozconexp.Tert=pozcon.Tert and pozconexp.Contract=pozcon.Contract and pozconexp.Cod=pozcon.Cod and pozconexp.Numar_pozitie=pozcon.Numar_pozitie 
LEFT JOIN pozcon pozconexp2 ON pozconexp2.Subunitate='EXPAND2' and pozconexp2.Tip=pozcon.Tip and pozconexp2.Data=pozcon.Data 
	and pozconexp2.Tert=pozcon.Tert and pozconexp2.Contract=pozcon.Contract and pozconexp2.Cod=pozcon.Cod and pozconexp2.Numar_pozitie=pozcon.Numar_pozitie 
LEFT JOIN con ON con.Subunitate=pozcon.Subunitate and con.Tip=pozcon.Tip and con.Data=pozcon.Data and con.Tert=pozcon.Tert and con.Contract=pozcon.Contract
LEFT JOIN nomencl on nomencl.Cod=pozcon.Cod
LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
WHERE pozcon.Subunitate NOT LIKE 'EXPAND%' AND pozcon.Tip='BK'
GO
select * from yso.pozconexp -- where Contract='TEST'