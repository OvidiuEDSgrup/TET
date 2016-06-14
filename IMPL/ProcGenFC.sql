ALTER procedure ProcGenFC @cUtilizator char(10) as
--DECLARE @cUtilizator char(10) SET @cUtilizator='OVIDIU' 
declare @Subunitate char(9), @cHostId char(8)
	,@cContract VARCHAR(20), @dData DATETIME, @cFurnizor CHAR(13), @dTermenJos datetime, @dTermenSus datetime
	,@cParametruLista VARCHAR(9), @lEsteListaSalvata BIT, @cListaParametriAplicatie VARCHAR(200)
	,@randuri int, @lFiltruTermen int 

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Subunitate output
set @cHostId=host_id()
SET @cParametruLista= LEFT(@cUtilizator,9)
EXECUTE luare_date_par @tip='GA', @par= @cParametruLista, @val_l= @lEsteListaSalvata OUTPUT, @val_n=0, @val_a=@cListaParametriAplicatie OUTPUT

SELECT TOP 1 @cContract=contract, @dData=data, @cFurnizor=tert, @dTermenJos=termenejos, @dTermenSus=termenesus, @lFiltruTermen=filtru_termene
from tmpparcomaprov
where utilizator=@cUtilizator

IF RTRIM(LTRIM(@cListaParametriAplicatie))<>''
BEGIN
	SET @cContract= ISNULL(@cContract,LTRIM(LEFT(@cListaParametriAplicatie,13)))
	SET @dData= ISNULL(@dData, CONVERT(DATETIME,LTRIM(SUBSTRING(@cListaParametriAplicatie,14,10)),103))
	SET @cFurnizor= ISNULL(@cFurnizor, LTRIM(SUBSTRING(@cListaParametriAplicatie,37,13)))
END
--SET @lFiltruTermen= CASE WHEN ISNULL(@dTermenJos,'')>'1901-01-01' AND ISNULL(@dTermenSus,'')>'1901-01-01' THEN 1 ELSE 0 END

/*
select * 
from tmpparcomaprov 
where utilizator=@cUtilizator
*/

DELETE pozaprov WHERE Contract= @cContract AND Data= @dData AND Furnizor= @cFurnizor and Tip='BK'
set @randuri=@@ROWCOUNT

UPDATE comaprovtmp SET De_aprovizionat= De_aprovizionat-Com_clienti, Com_clienti= 0
WHERE utilizator= @cUtilizator

--comenzi clienti
--insert into pozaprov
--(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select @cContract, @dData, @cFurnizor,
p.cod, 'BK', p.contract, p.data, p.tert, 
sum(dbo.valoare_maxima((p.cantitate
	-dbo.valoare_maxima(p.Cant_aprobata,p.Cant_rezervata+p.Cant_realizata,0)
	-p.Cant_comandata)
	--dbo.valoare_maxima(p.Cant_stoc_gest-p.Cantitate_altele,0,null)
	,0,null)) as Cant_de_aprovizionat
,0, 0
from yso.pozconexp p 
inner join con c on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.data=p.data and c.tert=p.tert
inner join nomencl n on p.cod=n.cod
where c.subunitate='1' 
and (@cFurnizor='.' or n.Furnizor=@cFurnizor)
and n.tip in ('A', 'M') and p.tip='BK' and c.Stare>='1' and p.UM='1'
--and (0=0 or p.factura='101') 
--and (0=0 or n.cod like RTrim('')) 
and dbo.valoare_maxima((p.cantitate
	-dbo.valoare_maxima(p.Cant_aprobata,p.Cant_rezervata+p.Cant_realizata,0)
	-p.Cant_comandata)
	--dbo.valoare_maxima(p.Cant_stoc_gest-p.Cantitate_altele,0,null)
	,0,null)>=0.001 
and (@lFiltruTermen=0 or p.termen between @dTermenJos and @dTermenSus)
--and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
group by p.contract, p.data, p.tert, p.cod

delete from pozaprov where contract=@cContract and data=@dData and furnizor=@cFurnizor AND Tip='BK' and cant_comandata < 0.001

--select * from comaprovtmp where utilizator=@cUtilizator
/*
IF OBJECT_ID('tempdb..#codGestComLivr') IS NOT NULL
DROP TABLE	#codGestComLivr

SELECT p.Cod,MAX(p.Contract) AS Contract,MAX(ISNULL(NULLIF(p.Punct_livrare,''), p.Factura)) AS Gestiune,SUM(pa.Cant_comandata) AS Cant_comandata
INTO #codGestComLivr
FROM pozaprov pa
	inner join pozcon p ON p.Subunitate=@Subunitate and pa.Tip=p.Tip and pa.Beneficiar=p.Tert and pa.Comanda_livrare=p.Contract 
		and pa.Data_comenzii=p.Data and pa.Cod=p.Cod
WHERE pa.Tip='BK' 
GROUP BY p.Cod

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #codGestComLivr (Cod)
CREATE UNIQUE NONCLUSTERED INDEX Contract ON #codGestComLivr (Cod,Contract)
CREATE UNIQUE NONCLUSTERED INDEX Gestiune ON #codGestComLivr (Cod,Gestiune)
*/

INSERT comaprovtmp
SELECT
p.cod --Cod	char	30
,@cFurnizor --Furnizor	char	13
,''	--Den_furnizor	char	80
,0	--Total	float	8
,0	--Media	float	8
,SUM(p.Cant_comandata)	--Com_clienti	float	8
,0	--Stoc	float	8
,0	--Stoc_limita	float	8
,0	--Comandate	float	8
,0	--De_aprovizionat	float	8
,0	--Pret	float	8
,''	--Termen	datetime	8
,@cUtilizator	--Utilizator	char	10
,0	--Com_interne	float	8
FROM pozaprov p
WHERE  contract=@cContract and data=@dData and furnizor=@cFurnizor AND Tip='BK'
and p.Cod not in (select cod from comaprovtmp where utilizator=@cUtilizator)
GROUP BY p.Cod

update comaprovtmp
set com_clienti = isnull((select sum(cant_comandata) from pozaprov p where p.contract=@cContract and p.data=@dData and p.furnizor=@cFurnizor 
	and p.cod=comaprovtmp.cod and p.tip='BK' and p.comanda_livrare<>'' group by p.cod), 0)
where utilizator=@cUtilizator

update comaprovtmp set de_aprovizionat=de_aprovizionat+com_clienti where utilizator=@cUtilizator

update comaprovtmp set de_aprovizionat=0 where de_aprovizionat<0.001 and utilizator=@cUtilizator

delete from pozaprov where contract=@cContract and data=@dData and furnizor=@cFurnizor AND Tip='BK' 
	and cod not in (select distinct cod from comaprovtmp where utilizator=@cUtilizator)

delete from pozaprov where contract=@cContract and data=@dData and furnizor=@cFurnizor 
	and cod in (select cod from comaprovtmp where utilizator=@cUtilizator group by cod having sum(de_aprovizionat)<0.001) 
	and comanda_livrare <> ''
GO
--select *,p.Contract,p.Cod,p.Cantitate,p.Cant_aprobata,p.Cant_realizata,p.Cant_comandata,p.Cant_rezervata,p.Cant_stoc_gest,p.Cantitate_altele
--from yso.pozconexp p
--order by p.Contract,p.Cod