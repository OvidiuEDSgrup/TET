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

update necesaraprov set 
stare=(case when stare='0' then '0' when isnull(p.receptionat, 0)>=n.cantitate then '3' when isnull(p.comandat, 0)>0 then '2' else '1' end)
from necesaraprov n 
left outer join
	(select p.comanda_livrare as numar, p.data_comenzii as data, p.cod, sum(p.cant_comandata) as comandat, sum(p.cant_receptionata) as receptionat
	from pozaprov p
	where p.tip='N' and p.beneficiar='' 
	group by p.comanda_livrare, p.data_comenzii, p.cod) p
on n.numar=p.numar and n.data=p.data and n.cod=p.cod

--UPDATE pozcon SET 
----SELECT 
--Termen=DATEADD(day,ISNULL(NULLIF(dbo.verificNumar(
--	COALESCE(
--		(SELECT TOP 1 pr.valoare FROM proprietati pr WHERE pr.tip='NOMENCL' AND pr.cod=pozcon.cod AND pr.cod_proprietate='ATP' ORDER BY pr.valoare DESC)
--		,'')
--	),0),30),@data)
--FROM comaprovtmp pozcon 
--	INNER JOIN nomencl ON pozcon.Cod=nomencl.Cod
--	LEFT JOIN grupe ON grupe.Tip_de_nomenclator=nomencl.Tip AND grupe.Denumire=nomencl.Grupa
--	LEFT JOIN terti ON terti.Subunitate=@Subunitate AND terti.Tert=nomencl.Furnizor
--WHERE pozcon.Utilizator=@utilizator
