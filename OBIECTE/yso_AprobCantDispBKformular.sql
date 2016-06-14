drop PROCEDURE yso_AprobCantDispBKformular

go
CREATE PROCEDURE yso_AprobCantDispBKformular @cHostId char(25) AS   
--DECLARE @cHostId char(10) SET @cHostId='13832'  
DECLARE @Sub CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME     

set @cHostId=isnull((select s.utilizator from asisria..sesiuniria s where s.token=@cHostId),@cHostId)  

select top 1 @Sub=con.Subunitate, @Tip=con.Tip, @Contract=con.Contract, @Tert=con.Tert, @Data=con.Data
FROM con JOIN avnefac ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract   
and avnefac.cod_tert=con.tert and avnefac.data=con.data and avnefac.Terminal=@cHostID  

if isnull((select max(stare) from con where subunitate=@sub and tip=@tip and contract=@contract and tert=@tert and data=@data),0)<'1'
	EXEC yso_AprobCantDispBK @sub, @tip, @contract, @data, @tert
  
--DECLARE @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME   
  
--UPDATE con  
--SET Stare='1'  
--FROM con JOIN avnefac ON avnefac.subunitate=con.subunitate and avnefac.tip=con.tip and avnefac.contractul=con.contract   
--and avnefac.cod_tert=con.tert and avnefac.data=con.data and avnefac.Terminal=@cHostID  
--WHERE stare<'1'  