SELECT 
ISNULL(REPLACE(REPLACE((select REPLACE(rtrim(p.contract)+'_pt_'+RTRIM(max(t.denumire))+'_cod_'+rtrim(p.tert),' ','_') 
from pozcon p left join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert 
where p.Subunitate=s.Subunitate and p.Tip='BK' and p.Contract=s.Contract 
GROUP BY p.Contract,p.Tert FOR XML PATH('')),' ',';'),'_',' '),'')

,ISNULL(REPLACE(REPLACE((select REPLACE(rtrim(CONVERT(varchar,SUM(p.cantitate)))+'_'+rtrim(isnull(max(n.UM),'')) 
+'_cu_'+RTRIM(p.Tip)+'_'+rtrim(p.numar)+'_din_'+rtrim(convert(varchar,p.data,102)),' ','_') 
from pozdoc p where p.Subunitate=s.Subunitate and p.Tip='TE' and p.Factura=s.Contract and p.Gestiune_primitoare=s.Cod_gestiune 
and p.Grupa=s.Cod_intrare and p.stare not in ('4', '6') and p.cantitate>0 
GROUP BY p.Tip,p.Numar,p.Data FOR XML PATH('')),' ','_'),'_',' '),'')

,ISNULL(REPLACE(REPLACE((select REPLACE(rtrim(CONVERT(varchar,SUM(p.cantitate)))+'_'+rtrim(isnull(max(n.UM),'')) 
+'_cu_'+RTRIM(p.Tip)+'_'+rtrim(p.numar)+'_din_'+rtrim(convert(varchar,p.data,102)),' ','_') 
from pozdoc p where p.Subunitate=s.Subunitate and p.Tip='AP' and p.Contract=s.Contract and p.Gestiune=s.Cod_gestiune and p.Cod_intrare=s.Cod_intrare and p.cantitate>0 
GROUP BY p.Tip,p.Numar,p.Data FOR XML PATH('')),' ',';'),'_',' '),'')
,s.Subunitate, s.Contract, s.Tip_gestiune, s.Cod_gestiune, s.Cod, s.Cod_intrare, s.Data
FROM STOCURI s 
	left join GESTIUNI g ON s.Subunitate=g.Subunitate and s.Tip_gestiune=g.Tip_gestiune and s.Cod_gestiune=g.Cod_gestiune 
	left join NOMENCL n on n.Cod=s.Cod 
	left join avnefac on avnefac.Subunitate=s.Subunitate and avnefac.Factura=s.Cod 
	LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
WHERE s.Tip_gestiune NOT IN ('F','T') and s.Contract<>'' 
	AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 
	AND s.Stoc>0.001 
GROUP BY s.Subunitate, s.Contract, s.Tip_gestiune, s.Cod_gestiune, s.Cod, s.Cod_intrare, s.Data
ORDER BY s.Subunitate, s.Contract, s.Tip_gestiune, s.Cod_gestiune, s.Cod, s.Cod_intrare, s.Data

FROM avnefac JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert and avnefac.data=con.data 
JOIN yso.pozconexp pozcon ON pozcon.subunitate=con.subunitate and pozcon.tip=con.tip and pozcon.contract=con.contract and pozcon.data=con.data and pozcon.tert=con.tert 
LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert LEFT JOIN nomencl ON nomencl.cod=pozcon.cod and nomencl.cod=pozcon.cod