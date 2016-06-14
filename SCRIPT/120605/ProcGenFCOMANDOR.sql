ALTER procedure ProcGenFC @cUtilizator char(10) as
declare @Sb char(9), @cHostId char(8)
	,@cContract VARCHAR(20), @dData DATETIME, @cFurnizor VARCHAR(13), @dTermenJos datetime, @dTermenSus datetime
	,@cParametruLista VARCHAR(9), @lEsteListaSalvata BIT, @cListaParametriAplicatie VARCHAR(200)
	,@randuri int, @lFiltruTermen bit

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
set @cHostId=host_id()
SET @cParametruLista= LEFT(@cUtilizator,9)
EXECUTE luare_date_par @tip='GA', @par= @cParametruLista, @val_l= @lEsteListaSalvata OUTPUT, @val_n=0, @val_a=@cListaParametriAplicatie OUTPUT

SELECT TOP 1 @cContract=contract, @dData=data, @cFurnizor=tert, @dTermenJos=termenejos, @dTermenSus=termenesus
from tmpparcomaprov
where utilizator=@cUtilizator


IF RTRIM(LTRIM(@cListaParametriAplicatie))<>''
BEGIN
	SET @cContract= ISNULL(@cContract,LTRIM(LEFT(@cListaParametriAplicatie,13)))
	SET @dData= ISNULL(@dData, CONVERT(DATETIME,LTRIM(SUBSTRING(@cListaParametriAplicatie,14,10)),103))
	SET @cFurnizor= ISNULL(@cFurnizor, LTRIM(SUBSTRING(@cListaParametriAplicatie,37,13)))
END

SET @lFiltruTermen= CASE WHEN ISNULL(@dTermenJos,'')>'1901-01-01' AND ISNULL(@dTermenSus,'')>'1901-01-01' THEN 1 ELSE 0 END

/*
select *
from comaprovtmp 
where utilizator=@cUtilizator
*/

DELETE pozaprov WHERE Contract= @cContract AND Data= @dData AND Furnizor= @cFurnizor and Tip='BK'
set @randuri=@@ROWCOUNT

UPDATE comaprovtmp SET De_aprovizionat= De_aprovizionat-Com_clienti, Com_clienti= 0
WHERE utilizator= @cUtilizator

--comenzi clienti
insert into pozaprov
(Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata)
select @cContract, @dData, @cFurnizor,
p.cod, 'BK', p.contract, p.data, p.tert, 
sum(p.cant_aprobata)-sum(CASE WHEN p.cant_realizata>=p.Pret_promotional THEN p.Cant_realizata ELSE p.Pret_promotional END)
	-isnull((select sum(cant_comandata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=p.contract 
	and pa.data_comenzii=p.data and pa.beneficiar=p.tert and pa.cod=p.cod and abs(pa.cant_realizata)<0.001), 0), 
0, 0
from con c inner join pozcon p on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.data=p.data and c.tert=p.tert
inner join nomencl n on p.cod=n.cod
where c.subunitate='1' and n.Furnizor=@cFurnizor
and n.tip in ('A', 'M') and p.tip='BK' and (c.stare = '1' or c.stare='0' and p.UM='1')
--and (0=0 or p.factura='101') 
--and (0=0 or n.cod like RTrim('')) 
and p.cant_aprobata-(CASE WHEN p.cant_realizata>=p.Pret_promotional THEN p.Cant_realizata ELSE p.Pret_promotional END)>=0.001 
and (@lFiltruTermen=0 or p.termen between @dData and @dData)
--and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
group by p.contract, p.data, p.tert, p.cod

delete from pozaprov where contract=@cContract and data=@dData and furnizor=@cFurnizor AND Tip='BK' and cant_comandata < 0.001

update comaprovtmp
set com_clienti = isnull((select sum(cant_comandata) from pozaprov p where p.contract=@cContract and p.data=@dData and p.furnizor=@cFurnizor and p.cod=comaprovtmp.cod and p.tip='BK' and p.comanda_livrare<>'' group by p.cod), 0)
where utilizator=@cUtilizator

delete from pozaprov where contract=@cContract and data=@dData and furnizor=@cFurnizor AND Tip='BK' 
	and cod not in (select distinct cod from comaprovtmp where utilizator=@cUtilizator)

if 0=0 update comaprovtmp set de_aprovizionat=0 where de_aprovizionat<0.001 and utilizator=@cUtilizator

update comaprovtmp set de_aprovizionat=de_aprovizionat+com_clienti where utilizator=@cUtilizator

update comaprovtmp set de_aprovizionat=0 where de_aprovizionat<0.001 and utilizator=@cUtilizator

delete from pozaprov where contract=@cContract and data=@dData and furnizor=@cFurnizor 
	and cod in (select cod from comaprovtmp where utilizator=@cUtilizator group by cod having sum(de_aprovizionat)<0.001) 
	and comanda_livrare <> ''

