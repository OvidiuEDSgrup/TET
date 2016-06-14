DECLARE @data1 datetime, @data2 datetime,@tert varchar(max),@comanda varchar(max), @stare varchar(max),@bifa varchar(max)
SET @data1='2012-02-10'
SET @data2='2012-02-10'
SET @tert=null
SET @comanda=null
SET @stare=''
SET @bifa='1'

DECLARE	@lRezStocBK bit, @cListaGestRezStocBK CHAR(200),@Subunitate CHAR(9), @Tip CHAR(2),@cUtilizator char(10)
SET @cUtilizator=LEFT(dbo.fIaUtilizator(null),10)
SET @Subunitate='1'
SET @Tip='BK'

EXEC luare_date_par 'GE', 'REZSTOCBK', @lRezStocBK OUTPUT, 0, @cListaGestRezStocBK OUTPUT

IF OBJECT_ID('tempdb..#cantComTermen') IS NOT NULL
DROP TABLE	#cantComTermen

SELECT Subunitate, Tip, Contract, Tert, Cod, Data, MAX(T.termen) AS Termen, SUM(t.Cantitate) AS Cant_comandata
INTO #cantComTermen
FROM Termene t
WHERE t.Subunitate=@Subunitate and t.Tip=@Tip and (@data2 IS NULL OR t.Termen <= @data2) and t.Cantitate>0
GROUP BY Subunitate, Tip, Contract, Tert, Cod, Data

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #cantComTermen (Subunitate, Tip, Contract, Tert, Cod, Data)

DELETE pozcomlivrtmp 
WHERE utilizator=@cUtilizator

--select * from #cantComTermen
INSERT pozcomlivrtmp 
(utilizator, cod, comanda, tert, cant_comandata
,cant_aprobata, termen, numar_document, data_document, stare, selectat, observatii)
select @cUtilizator,p.Cod,p.Contract, MAX(p.Tert)
,SUM(ISNULL(ct.Cant_comandata, p.cantitate)-(p.Cant_rezervata+p.Cant_realizata))
,SUM(p.cant_aprobata-(Cant_rezervata+Cant_realizata))
,min(p.termen), '', '01/01/1901', MAX(c.stare), 0, ''
from yso.pozconexp p 
inner join con c on p.subunitate = c.subunitate and p.tip = c.tip and p.contract = c.contract and p.data = c.data 
	and p.tert = c.tert 
inner join nomencl n on p.cod = n.cod
left outer join terti t on t.subunitate=p.subunitate and t.tert=p.tert
left join #cantComTermen ct ON ct.Subunitate=p.Subunitate and ct.Tip=p.Tip and ct.Contract=p.Contract and ct.Tert=p.Tert and ct.Cod=p.Cod
	and ct.data=p.Data
where p.subunitate = @Subunitate and p.tip =@Tip and p.cantitate>0 and n.tip not in ('R', 'S')
and (isnull(@stare,'')='' OR  c.stare = @stare)
--and (1  = 0 or p.factura = '101      ')
--and (0  = 0 or charindex(';' + rtrim(p.punct_livrare) + ';', ';;') > 0) 
--and (0  = 0 or charindex(';' + rtrim(n.grupa) + ';', ';;') > 0) 
and (isnull(@comanda, '') = '' OR  p.Contract= rtrim(rtrim(@comanda)))
--and ((0 = 0 or charindex(';' + rtrim(c.loc_de_munca) + ';', '') > 0) 
--or (0 = 0 or rtrim(c.loc_de_munca)  like '%'))
--and (0 = 0 or p.data between '02/01/2012' and '02/29/2012')
and (@data2 IS NULL OR ISNULL(ct.termen,p.termen) <= @data2)
--and (0 = 0 or n.grupa like RTrim('             ')+'%')
--and (0 = 0 or charindex(';' + rtrim(isnull(t.grupa,'')) + ';', ';;') > 0) 
and (isnull(@tert, '') = '' OR  p.Tert= rtrim(rtrim(@tert)))
--and (0 = 0 or charindex(';' + rtrim(c.punct_livrare) + ';', ';;') > 0)
--and (0=0 or c.mod_penalizare like rtrim('                                                                                                    ')+'%')
and (isnull(@Bifa, '') = '' OR p.cantitate-p.Cant_aprobata>=0.001)
group by p.cod, p.contract

delete comlivrtmp
where utilizator=@cUtilizator

insert into comlivrtmp
(utilizator, cod, cant_comandata, stoc, cant_aprobata, aprobat_alte, stare)
select @cUtilizator, cod, sum(cant_comandata), 0, sum(cant_aprobata), 0, ''
from pozcomlivrtmp
where utilizator=@cUtilizator
group by cod

IF OBJECT_ID('tempdb..#codGestComLivr') IS NOT NULL
DROP TABLE	#codGestComLivr

SELECT pc.Cod, MAX(Contract) AS Contract, MAX(ISNULL(NULLIF(Punct_livrare,''), Factura)) AS Gestiune
	,MAX(pozcon.Cant_aprobata) AS Cant_aprobata
INTO #codGestComLivr
FROM pozcomlivrtmp pc
JOIN pozcon ON pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=pc.Comanda AND pozcon.Tert=pc.Tert 
	AND pozcon.Cod=pc.Cod
GROUP BY pc.Cod

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #codGestComLivr (Cod)
CREATE UNIQUE NONCLUSTERED INDEX Total ON #codGestComLivr (Cod,Contract,Gestiune)

update comlivrtmp
set stoc = isnull(stocGest.Stoc, 0)
from comlivrtmp c 
LEFT JOIN 
(SELECT s.cod, SUM(Stoc) AS Stoc
FROM dbo.stocuri s INNER JOIN #codGestComLivr c ON c.Cod=s.Cod
WHERE s.Subunitate=@Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 
	AND (s.Cod_gestiune=c.Gestiune AND s.Contract=c.Contract
		OR s.Cod_gestiune=c.Gestiune AND s.Contract=''
		OR CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';')>0 AND s.Contract=''
		OR s.Contract=c.Contract)
GROUP BY s.Cod) stocGest ON stocGest.Cod=c.Cod
where utilizator=@cUtilizator

update comlivrtmp
set aprobat_alte = 
isnull((select sum(Cant_aprobata- (Cant_rezervata+Cant_realizata)) 
 from yso.pozconexp p join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Data=p.Data and c.Tert=p.Tert and c.Contract=p.Contract 
 where p.subunitate='1' and p.tip='BK'  and c.stare <='1' and p.cod=comlivrtmp.cod and (1=0 or p.factura='101      ')), 0)
where utilizator=@cUtilizator

update comlivrtmp
set aprobat_alte = aprobat_alte - cant_aprobata
where utilizator=@cUtilizator

DROP TABLE	#codGestComLivr
DROP TABLE	#cantComTermen

--SELECT * from #cantComTermen
select ltrim(rtrim(p.tert))+' - '+(select ltrim(rtrim(denumire)) from terti where tert=p.tert) as tert,c.stare,
p.Comanda,p.Termen,p.Cod, p.Cant_comandata as cantComandata,
0 as cantRealizata, p.Cant_aprobata as diferenta,
 a.contract as comanda,a.Data as dataComAprov,
 ROW_NUMBER() OVER(ORDER BY p.cod) as nr,
 ct.stoc as stocCurent 
 from pozcomlivrtmp p
 inner join con c on p.Comanda=c.Contract and p.Tert=c.Tert and c.Tip=@Tip
 left join pozaprov a on p.Comanda=a.comanda_livrare and a.Beneficiar=p.Tert and p.Cod=a.Cod and a.tip=c.Tip
 left join comlivrtmp ct on ct.Utilizator=@cUtilizator and ct.Cod=p.Cod
-- where p.Cod like '3-%'
--order by p.Comanda, p.cod
 --select * from pozcomlivrtmp p  where p.Cod like '3-%' order by p.Comanda, p.cod
 --select * from yso.pozconexp p where p.Cod like '3-%'
 --order by Contract,cod