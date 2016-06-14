drop proc yso.ProcGenFCPozaprov
GO
CREATE procedure [yso].[ProcGenFCPozaprov] @utilizator char(10),@contract VARCHAR(20), @data DATETIME, @furnizor CHAR(13), 
	@termenJos datetime, @termenSus datetime,@filtruTermen int, @gestiune char(9) as
--DECLARE @utilizator char(10) SET @utilizator='OVIDIU' 
declare @Subunitate char(9), @cHostId char(8),@randuri int

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Subunitate output
set @cHostId=host_id()

IF OBJECT_ID('tempdb..#pozconBKfaraStoc') IS NOT NULL
	DROP TABLE	#pozconBKfaraStoc

select p.Subunitate, p.cod, p.Tip, p.contract, p.data, p.tert, MAX(p.termen) as Termen, Max(p.UM) as UM
,SUM(p.Cantitate) as Cantitate
,SUM(p.Cant_aprobata) as Cant_aprobata
,Cant_realizata=SUM(dbo.valoare_maxima(rez.Cant_rezervata+p.Cant_realizata,dbo.valoare_maxima(te.Transferuri,ap.Avize+ae.AlteIesiri,null),null))
,SUM(com.Cant_comandata) as Cant_comandata
--,dbo.valoare_maxima(
--(SELECT SUM(dbo.valoare_maxima(pa.Cantitate
--	-dbo.valoare_maxima(rez.Cant_rezervata+pa.Cant_realizata,dbo.valoare_maxima(te.Transferuri,ap.Avize+ae.AlteIesiri,null),null),0,null))
--FROM yso.pozconexp pa WHERE pa.Subunitate=p.Subunitate and pa.Tip=p.tip and pa.Cod=p.Cod and pa.Cantitate>0
--	and pa.Factura=MAX(p.Factura))
---SUM(p.Cantitate),0,null) 
,0 as Cantitate_alte
INTO #pozconBKfaraStoc
from yso.pozconexp p 
inner join con c on c.subunitate=p.subunitate and c.tip=p.tip and c.contract=p.contract and c.data=p.data and c.tert=p.tert
inner join nomencl n on p.cod=n.cod
left join par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
outer apply (SELECT SUM(Stoc) AS Cant_rezervata
		FROM dbo.stocuri s LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
		WHERE s.Subunitate=p.subunitate and s.Tip_gestiune NOT IN ('F','T') and s.Contract=p.Contract and s.Cod=p.Cod
			AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 
			AND s.Stoc>0.001) rez
outer apply (select Cant_comandata=sum(pa.cant_comandata-pa.cant_realizata) from pozaprov pa where pa.tip='BK' and pa.comanda_livrare=p.contract 
		and pa.data_comenzii=p.data and pa.beneficiar=p.tert and pa.cod=p.cod /*and abs(pa.cant_realizata)<0.001*/) com 
outer apply	(SELECT Cant_stoc_gest=SUM(Stoc)
		FROM dbo.stocuri s 
		WHERE s.Subunitate=p.Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 AND p.Cod=s.Cod
			AND (s.Cod_gestiune=ISNULL(NULLIF(p.Punct_livrare,''), p.Factura) AND s.Contract=p.Contract
				OR s.Cod_gestiune=ISNULL(NULLIF(p.Punct_livrare,''), p.Factura) AND s.Contract=''
				OR CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 AND s.Contract=''
				OR s.Contract=p.Contract)) st
outer apply (select Transferuri=SUM(d.cantitate)
		from pozdoc d 
		WHERE d.Subunitate=p.Subunitate and d.Tip='TE' and d.Factura=p.Contract 
			and d.Gestiune=ISNULL(NULLIF(p.Punct_livrare,''), p.Factura) AND d.Cod=p.Cod 
			AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(d.Gestiune_primitoare)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 
			AND d.cantitate>0 and d.stare not in ('4', '6')) te
outer apply (select Avize=SUM(p.cantitate)
		from pozdoc p where p.Subunitate=p.Subunitate and p.Tip='AP' and p.Contract=p.Contract 
			--and p.Gestiune=ISNULL(NULLIF(p.Punct_livrare,''), p.Factura)
			and p.Cod=p.cod and p.cantitate>0) ap
outer apply (select AlteIesiri=SUM(p.cantitate)
		from pozdoc p where p.Subunitate=p.Subunitate and p.Tip='AE' and p.grupa=p.Contract 
			--and p.Gestiune=ISNULL(NULLIF(p.Punct_livrare,''), p.Factura)
			and p.Cod=p.cod and p.cantitate>0) ae
where c.subunitate='1' 
and n.Furnizor<>'' and (@furnizor='.' or n.Furnizor=@furnizor )
and ISNULL(nullif(p.Punct_livrare,''),p.Factura)=@gestiune
and n.tip in ('A', 'M') and p.tip='BK' and c.Stare='1' and p.UM='1'
--and (0=0 or p.factura='101') 
--and (0=0 or n.cod like RTrim('')) 
and (@filtruTermen=0 or p.termen between @termenJos and @termenSus)
--and (charindex(','+rtrim(n.grupa)+',','') > 0 or 0 = 0)
group by p.Subunitate, p.cod, p.Tip, p.contract, p.data, p.tert


select @contract, @data, n.Furnizor,
p.cod, 'BK', p.contract as Comanda_livrare, p.data as Data_comenzii, p.tert as Beneficiar, 
dbo.valoare_maxima(p.cantitate-p.Cant_realizata-p.Cant_comandata-p.Cant_aprobata,0,null) as Cant_de_aprovizionat
	--p.Cant_comandata)
	---dbo.valoare_maxima(p.Cant_stoc_gest-p.Cantitate_alte,0,null)
,0, 0
from #pozconBKfaraStoc p 
left join nomencl n on p.cod=n.cod
where p.cantitate>0
and dbo.valoare_maxima(p.cantitate-p.Cant_realizata-p.Cant_comandata-p.Cant_aprobata,0,null)>=0.001 
--group by p.Subunitate, p.cod, p.Tip, p.contract, p.data, p.tert

IF OBJECT_ID('tempdb..#pozconBKfaraStoc') IS NOT NULL
	DROP TABLE	#pozconBKfaraStoc