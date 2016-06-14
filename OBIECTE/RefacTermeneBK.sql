ALTER PROCEDURE yso.RefacTermeneBK @hostID char(10) AS 
--DECLARE @hostID char(10)
DECLARE @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME 

SET @hostID=HOST_ID()

DECLARE comLivrNefac CURSOR FOR
select a.subunitate, a.tip, a.contractul, a.data, a.cod_tert from dbo.avnefac a where a.terminal=@hostID
ORDER BY a.subunitate, a.tip, a.contractul, a.data, a.cod_tert
 
OPEN comLivrNefac 

FETCH NEXT FROM comlivrnefac INTO @subunitate, @tip, @contract, @data, @tert
WHILE @@FETCH_STATUS<>-1
BEGIN
	EXEC yso.DefalcTermeneBK @subunitate, @tip, @contract, @data, @tert
	FETCH NEXT FROM comlivrnefac INTO @subunitate, @tip, @contract, @data, @tert
END

CLOSE comlivrnefac
DEALLOCATE comlivrnefac

/*
DECLARE @hostID char(10)

SET @hostID=HOST_ID()

--delete avnefac where Terminal=@hostID 
--insert avnefac
select DISTINCT
@hostID	--Terminal	char	10
,c.Subunitate	--Subunitate	char	9
,c.tip	--Tip	char	2
,''	--Numar	char	20
,''	--Cod_gestiune	char	9
,c.Data	--Data	datetime	8
,c.Tert	--Cod_tert	char	13
,''	--Factura	char	20
,c.Contract	--Contractul	char	20
,''	--Data_facturii	datetime	8
,''	--Loc_munca	char	9
,''	--Comanda	char	13
,''	--Gestiune_primitoare	char	9
,''	--Valuta	char	3
,0	--Curs	float	8
,0	--Valoare	float	8
,0	--Valoare_valuta	float	8
,0	--Tva_11	float	8
,0	--Tva_22	float	8
,''	--Cont_beneficiar	char	13
,0	--Discount	real	4
--select c.stare,t.* 
from termene t join pozcon p on p.Subunitate=t.Subunitate and p.Tip=t.Tip and p.Contract=t.Contract 
and p.Tert=t.Tert and p.Data=t.Data and p.Cod=t.Cod
join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and p.Tert=c.Tert and p.Data=c.Data
where t.Subunitate='1' and t.Cantitate<0 and p.Cantitate>0

--exec yso.RefacTermeneBK @hostid
*/