
DECLARE test  CURSOR SCROLL DYNAMIC FOR
SELECT /*subunitate,tip,data,tert,contract,*/cod, cantitate ,(SELECT SUM (cantitate) FROM pozcon p WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
	and p.Contract=t.Contract and p.Cod=t.Cod and p.Termen=t.Termen)
from termene t
WHERE TIP='BK'
union all
SELECT /*subunitate,tip,data,tert,contract,*/cod, cantitate ,(SELECT SUM (cantitate) FROM pozcon p WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
	and p.Contract=t.Contract and p.Cod=t.Cod and p.Termen=t.Termen)
from termene t
WHERE TIP='BK'
--group by subunitate,tip,data,tert,contract,cod
--for update

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
