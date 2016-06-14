DROP procedure ProcGenFC 
GO
CREATE procedure ProcGenFC @utilizator char(10) as
--DECLARE @utilizator char(10) SET @utilizator='OVIDIU' 
declare @Subunitate char(9), @cHostId char(8)
	,@contract VARCHAR(20), @data DATETIME, @furnizor CHAR(13), @termenJos datetime, @termenSus datetime
	,@cParametruLista VARCHAR(9), @lEsteListaSalvata BIT, @cListaParametriAplicatie VARCHAR(200)
	,@randuri int, @filtruTermen int, @gestiune char(9)

if ISNULL(@utilizator,'')=''
	set @utilizator=dbo.fIaUtilizator(null)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Subunitate output
set @cHostId=host_id()
SET @cParametruLista= LEFT(@utilizator,9)
SET @gestiune='101'
EXECUTE luare_date_par @tip='GA', @par= @cParametruLista, @val_l= @lEsteListaSalvata OUTPUT, @val_n=0, @val_a=@cListaParametriAplicatie OUTPUT


SELECT TOP 1 @contract=contract, @data=data, @furnizor=tert, @termenJos=termenejos, @termenSus=termenesus, @filtruTermen=filtru_termene
from tmpparcomaprov
where utilizator=@utilizator

IF RTRIM(LTRIM(@cListaParametriAplicatie))<>''
BEGIN
	SET @contract= ISNULL(@contract,LTRIM(LEFT(@cListaParametriAplicatie,13)))
	SET @data= ISNULL(@data, CONVERT(DATETIME,LTRIM(SUBSTRING(@cListaParametriAplicatie,14,10)),103))
	SET @furnizor= ISNULL(@furnizor, LTRIM(SUBSTRING(@cListaParametriAplicatie,37,13)))
END
--SET @filtruTermen= CASE WHEN ISNULL(@termenJos,'')>'1901-01-01' AND ISNULL(@termenSus,'')>'1901-01-01' THEN 1 ELSE 0 END

/*
select * 
from tmpparcomaprov 
where utilizator=@utilizator
*/

DELETE pozaprov WHERE Contract= @contract AND Data= @data AND Furnizor= @furnizor and Tip='BK'

delete pozaprov 
from pozaprov pa --inner join comaprovtmp c on c.Cod=pa.Cod and c.Furnizor=pa.Furnizor and c.utilizator=@utilizator
where pa.Tip='BK' --  pa.contract=@contract and pa.data=@data
and not exists 
(select 1 from pozcon p where p.Subunitate=@Subunitate and p.Tip='FC' 
and p.Contract=pa.Contract and p.Data=pa.Data and p.Tert=pa.Furnizor)

UPDATE comaprovtmp SET De_aprovizionat= De_aprovizionat-Com_clienti, Com_clienti= 0
WHERE utilizator= @utilizator

--comenzi clienti
--insert into pozaprov
--(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
--exec yso.ProcGenFCPozaprov @utilizator=@utilizator,@contract=@contract, @data=@data, @furnizor=@furnizor, 
--	@termenJos=@termenJos, @termenSus=@termenSus,@filtruTermen=@filtruTermen, @gestiune=@gestiune

--delete from pozaprov where contract=@contract and data=@data /*and furnizor=@furnizor*/ AND Tip='BK' and cant_comandata < 0.001

--insert pozaprov
--select Contract, Data, '.', Cod, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata, Tip
--from pozaprov
--where contract=@contract and data=@data /*and furnizor=@furnizor*/ AND Tip='BK'

-- necesar de aprovizionare
--insert into pozaprov
--(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
--select '0', '01/01/2015', 'IT09076750158',
--na.cod, 'N', na.numar, na.data, '', 
--sum(na.cantitate)-isnull((select sum(pa.cant_comandata) from pozaprov pa where pa.tip='N' and pa.comanda_livrare=na.numar and pa.data_comenzii=na.data and pa.beneficiar='' and pa.cod=na.cod), 0), 
--0, 0
--from necesaraprov na
--inner join nomencl n on na.cod = n.cod
--where 1=1 and 2  in (0,2) and na.data between '01/01/2012' and '04/30/2012' and na.stare='1' and (1=0 or na.gestiune='101') 
--and (0=0 or na.cod like RTrim(''))  and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
--group by na.numar, na.data, na.cod

/*
select isnull(sum(pa.cant_comandata), 0), isnull(sum(pa.cant_receptionata), 0) 
from pozaprov pa 
where pa.tip='N' and pa.comanda_livrare='1       ' and pa.data_comenzii='11/30/2014' and pa.beneficiar='' and pa.cod='0003020             '
*/

delete comaprovtmp where utilizator=@utilizator

INSERT comaprovtmp
SELECT
p.cod --Cod	char	30
,max(p.Furnizor) --Furnizor	char	13
,MAX(/*ISNULL(t.Denumire,'')*/'')	--Den_furnizor	char	80
,0	--Total	float	8
,0	--Media	float	8
,SUM(p.Cant_comandata)	--Com_clienti	float	8
,0	--Stoc	float	8
,0	--Stoc_limita	float	8
,0	--Comandate	float	8
,0	--De_aprovizionat	float	8
,0	--Pret	float	8
,''	--Termen	datetime	8
,@utilizator	--Utilizator	char	10
,0	--Com_interne	float	8
FROM pozaprov p
--LEFT JOIN terti t on t.Subunitate=@Subunitate and t.Tert=p.Furnizor
WHERE  contract=@contract and data=@data AND Tip='BK' and p.furnizor<>'.'
--and p.Cod not in (select cod from comaprovtmp where utilizator=@utilizator)
GROUP BY p.Cod

update comaprovtmp
set com_clienti = isnull((select sum(cant_comandata) from pozaprov p where p.contract=@contract and p.data=@data and p.furnizor=@furnizor 
	and p.cod=comaprovtmp.cod and p.tip='BK' and p.comanda_livrare<>'' and p.Furnizor<>'.' group by p.cod), 0)
where utilizator=@utilizator and Com_clienti=0

update comaprovtmp
set Stoc=ISNULL((SELECT SUM(Stoc)
		FROM dbo.stocuri s 
		WHERE s.Subunitate=@Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND comaprovtmp.Cod=s.Cod
			AND (s.Cod_gestiune=@gestiune OR CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0)
			AND s.Contract='' AND s.Stoc>=0.001),0)
from comaprovtmp LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
where utilizator=@utilizator

update comaprovtmp
set Comandate=ISNULL(
	(SELECT SUM(dbo.valoare_maxima(pozcon.Cant_aprobata-pozcon.Cant_realizata,0,null))
		---ISNULL((SELECT SUM(Cant_comandata) FROM pozaprov WHERE pozaprov.Contract=pozcon.Contract 
		--	AND pozaprov.Data=pozcon.Data AND pozaprov.Furnizor=pozcon.Tert and pozaprov.cod=pozcon.cod AND pozaprov.tip='BK' 
		--	AND pozaprov.Comanda_livrare<>'' AND pozaprov.Cant_comandata>=0.001),0) AS Cant_libera
	FROM pozcon INNER JOIN con ON con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and con.data=pozcon.data 
		and con.tert=pozcon.tert and con.contract=pozcon.contract
	WHERE pozcon.cod=comaprovtmp.Cod AND pozcon.subunitate=@subunitate AND pozcon.tip='FC'
		--AND NOT EXISTS (SELECT 1 FROM pozcon p WHERE p.subunitate=pozcon.subunitate and p.tip=pozcon.tip 
		--and p.contract=pozcon.contract and p.data=pozcon.data and p.tert=pozcon.tert and ABS(pozcon.cant_realizata)>=0.001)
	),0)
from comaprovtmp 
where utilizator=@utilizator

update comaprovtmp
set Stoc_limita=Comandate
from comaprovtmp 
where utilizator=@utilizator

update comaprovtmp set de_aprovizionat=dbo.valoare_maxima(com_clienti/*-stoc-Comandate*/,0,null) where utilizator=@utilizator

update comaprovtmp set de_aprovizionat=0 where de_aprovizionat<0.001 and utilizator=@utilizator

--delete comaprovtmp where de_aprovizionat=0 and utilizator=@utilizator

--delete from pozaprov where contract=@contract and data=@data /*and furnizor=@furnizor*/ 
--	and cod in (select cod from comaprovtmp where utilizator=@utilizator group by cod having sum(de_aprovizionat)<0.001) 
--	and comanda_livrare <> ''

--delete from pozaprov where contract=@contract and data=@data /*and furnizor=@furnizor*/ AND Tip='BK' 
--	and cod not in (select distinct cod from comaprovtmp where utilizator=@utilizator)

--delete from pozaprov where contract=@contract and data=@data and furnizor='.' AND Tip='BK' 

GO
--select *,p.Contract,p.Cod,p.Cantitate,p.Cant_aprobata,p.Cant_realizata,p.Cant_comandata,p.Cant_rezervata,p.Cant_stoc_gest,p.Cantitate_altele
--from yso.pozconexp p
--order by p.Contract,p.Cod

--select * from pozaprov pa where pa.tip='BK' and not exists 
--(select 1 from pozcon p where p.Subunitate='1' and p.Tip='fc' 
--and p.Contract=pa.Contract and p.Data=pa.Data and p.Tert=pa.Furnizor)
--AND pa.Furnizor not in (select t.tert from terti t)

--select distinct cod from pozaprov pa where pa.tip='BK' and not exists 
--(select 1 from pozcon p where p.Subunitate='1' and p.Tip='fc' 
--and p.Contract=pa.Contract and p.Data=pa.Data and p.Tert=pa.Furnizor)
--AND pa.Furnizor not in (select t.tert from terti t)

--select * from comaprovtmp where utilizator='OVIDIU'

-- delete pozaprov from pozaprov pa where pa.tip='BK' and not exists 
--(select 1 from pozcon p where p.Subunitate='1' and p.Tip='fc' 
--and p.Contract=pa.Contract and p.Data=pa.Data and p.Tert=pa.Furnizor)