
-- daca inca mai am pozitii cu termenul necompletat trebuie sa pun :
-- daca furnizorul trecut la acel cod are contract se va trece ziua introducerii 
-- + campul scadenta de la contractul de tip FA de la acel tert din tabel con. 
-- Daca la acel cod nu are contract acel furnizor la termen pun ziua introducerii comenzii + 30 zile .
/*
UPDATE Termene
SET Cantitate=t.Cantitate+p.Cant_aprobata
	,Explicatii=RTRIM(ISNULL(NULLIF(t.Explicatii,'')+'(+)',''))+RTRIM(CONVERT(CHAR(20),p.Cant_aprobata))+' din Detalii comenzi aprovizionare '
FROM Termene t INNER JOIN pozcon p ON p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
	and p.Contract=t.Contract and p.Cod=t.Cod and p.Termen=t.Termen
WHERE p.Subunitate=@Subunitate AND p.Tip=@Tip AND p.Contract=@Contract AND p.Tert=@Tert AND p.Data=@Data 
	and p.Cant_aprobata>0 and p.Cant_aprobata<p.Cantitate
	
INSERT Termene
SELECT Subunitate,Tip,Contract,Tert,Cod,Data,@TermenMaxim,Cant_aprobata
,RTRIM(CONVERT(CHAR(20),p.Cant_aprobata))+' din Contract furnizor'
,0,0,0,0,'',''
FROM pozcon p 
WHERE p.Subunitate=@Subunitate AND p.Tip=@Tip AND p.Contract=@Contract AND p.Tert=@Tert AND p.Data=@Data AND p.Cod=@Cod
	and not exists (SELECT 1 FROM Termene t WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
		and p.Contract=t.Contract and p.Cod=t.Cod and p.Termen=t.Termen)
*/
			

GO
/*
DECLARE test  CURSOR SCROLL DYNAMIC FOR
SELECT /*subunitate,tip,data,tert,contract,*/cod, cantitate ,(SELECT SUM (cantitate) FROM pozcon p WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
	and p.Contract=t.Contract and p.Cod=t.Cod and p.Termen=t.Termen)
from termene t
WHERE TIP='BK'
--group by subunitate,tip,data,tert,contract,cod
for update

OPEN test
FETCH NEXT FROM test --INTO @subunitate,@tip,@data,@tert,@contract,@Cod,@CantLIVR

WHILE @@FETCH_STATUS=0
BEGIN
--UPDATE Termene
--SET Cantitate=Cantitate+1
--WHERE CURRENT OF test
--FETCH PRIOR FROM test
FETCH NEXT FROM TEST --INTO @subunitate,@tip,@data,@tert,@contract,@Cod,@CantLIVR
END
FETCH PRIOR FROM test
FETCH PRIOR FROM test

DECLARE @Report CURSOR

exec sp_cursor_list @cursor_return=@Report OUTPUT,@cursor_scope=3
WHILE @@FETCH_STATUS=0
BEGIN
--UPDATE Termene
--SET Cantitate=Cantitate+1
--WHERE CURRENT OF test
--FETCH PRIOR FROM test
FETCH NEXT FROM @Report --INTO @subunitate,@tip,@data,@tert,@contract,@Cod,@CantLIVR
END
CLOSE test
DEALLOCATE test
--*/

--extcon

--select * from yso.pozconexp order by contract