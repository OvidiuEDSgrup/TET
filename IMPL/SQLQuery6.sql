SELECT * FROM Termene WHERE TIP='BK'
SELECT * FROM pozaprov WHERE Comanda_livrare='51'
SELECT * FROM POZCON WHERE TIP='BK' and contract='51'
20/12/2011:2 din Detalii comenzi aproviz; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;

select RTRIM(CONVERT(CHAR,numar_pozitie))+RTRIM(CONVERT(CHAR(2000),EXPRESIE)) as [data()] from formular WHERE formular='termene' ORDER BY Numar_pozitie 
FOR XML PATH('')
SELECT *,
ISNULL((SELECT SUM(stoc) FROM stocuri s WHERE s.Subunitate=MAX(pozcon.Subunitate) AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 AND s.Cod=MAX(pozcon.Cod) AND (CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(ISNULL(MAX(Val_alfanumerica),''))+';')>0 AND s.Contract=MAX(pozcon.Contract) AND ISNULL(MAX(Val_logica+0),0)=1 OR s.Cod_gestiune=MAX(ISNULL(NULLIF(pozcon.Punct_livrare,''),pozcon.Factura)) AND (s.Contract=MAX(pozcon.Contract) OR s.Contract='') OR s.Contract=MAX(pozcon.Contract))),0)
		FROM POZCON
		GROUP BY SUBUNITATE
		
REPLACE((SELECT RTRIM(t.Explicatii)+' la '+LTRIM(RTRIM(CONVERT(CHAR,t.Termen,103)))+' ' AS [data()] FROM Termene t WHERE MAX(pozcon.Subunitate)=t.Subunitate AND MAX(pozcon.Tip)=t.Tip AND MAX(pozcon.Data)=t.Data and MAX(pozcon.Tert)=t.Tert and MAX(pozcon.Contract)=t.Contract and MAX(pozcon.Cod)=t.Cod ORDER BY t.Termen FOR XML PATH('')),'  ',CHAR(10)+CHAR(13))

'In Stoc'+(SELECT MAX('') FROM stocuri s WHERE s.Subunitate=MAX(pozcon.Subunitate) AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 AND s.Cod=MAX(pozcon.Cod) AND (CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(ISNULL(MAX(Val_alfanumerica),''))+';')>0 AND s.Contract=MAX(pozcon.Contract) AND ISNULL(MAX(Val_logica+0),0)=1 OR s.Cod_gestiune=MAX(ISNULL(NULLIF(pozcon.Punct_livrare,''),pozcon.Factura)) AND (s.Contract=MAX(pozcon.Contract) OR s.Contract='') OR s.Contract=MAX(pozcon.Contract)))