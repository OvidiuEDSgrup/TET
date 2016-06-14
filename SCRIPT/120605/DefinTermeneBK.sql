ALTER PROCEDURE yso.DefinTermeneBK @cHostID char(10) AS

--DECLARE @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME 

UPDATE con
SET Stare='1'
FROM con JOIN avnefac ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract 
and avnefac.cod_tert=con.tert and avnefac.data=con.data and avnefac.Terminal=@cHostID
WHERE stare<'1'