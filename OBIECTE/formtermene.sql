select *
FROM 
(SELECT avnefac.Terminal, doc.Subunitate, 'BK' AS Tip, doc.Contractul, doc.cod_tert FROM avnefac,doc 
WHERE doc.subunitate=avnefac.subunitate and doc.tip=avnefac.tip and doc.numar=avnefac.numar and avnefac.data=doc.data) avnefac 
JOIN con ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract and avnefac.cod_tert=con.tert 
JOIN yso.pozconexp pozcon ON pozcon.subunitate=con.subunitate and pozcon.tip=con.tip and pozcon.contract=con.contract and pozcon.data=con.data and pozcon.tert=con.tert 
LEFT JOIN terti ON terti.subunitate=con.subunitate and terti.tert=con.tert 
LEFT JOIN nomencl ON nomencl.cod=pozcon.cod and nomencl.cod=pozcon.cod 
LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK' 

REPLACE((SELECT RTRIM(t.Explicatii)+' la '+LTRIM(RTRIM(CONVERT(CHAR,t.Termen,103)))+' ' AS [data()] FROM Termene t 
WHERE MAX(pozcon.Subunitate)=t.Subunitate AND MAX(pozcon.Tip)=t.Tip AND MAX(pozcon.Data)=t.Data and MAX(pozcon.Tert)=t.Tert and MAX(pozcon.Contract)=t.Contract and MAX(pozcon.Cod)=t.Cod ORDER BY t.Termen FOR XML PATH('')),'  ',' (+) ')


