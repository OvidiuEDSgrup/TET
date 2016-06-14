REPLACE((SELECT CONVERT(varchar,t.Cantitate)+' la '+LTRIM(RTRIM(CONVERT(CHAR,t.Termen,103)))+' ' AS [data()] 
FROM Termene t WHERE MAX(pozcon.Subunitate)=t.Subunitate AND MAX(pozcon.Tip)=t.Tip AND MAX(pozcon.Data)=t.Data 
and MAX(pozcon.Tert)=t.Tert and MAX(pozcon.Contract)=t.Contract and MAX(pozcon.Cod)=t.Cod ORDER BY t.Termen FOR XML PATH('')),'  ',' (+) ')