
CREATE PROCEDURE [dbo].[CalculTermeneFC] @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME AS
--pun termen pe comanda livrare

DECLARE	@lRezStocBK bit, @cListaGestRezStocBK CHAR(200), @codLivr CHAR(30), @cantLivr FLOAT, @cantLibera FLOAT, @dTermenAprov DATETIME
	,@contrAprov CHAR(20), @cFurnAprov CHAR(13), @dataAprov DATETIME, @randuri INT
	
EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

--DECLARE @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Data DATETIME, @Tert CHAR(13)
--SELECT TOP 1 
--@Subunitate='1'
--,@Tip='FC'
--,@Contract=Contract
--,@Tert=Tert
--,@Data=data
--FROM pozcon where Contract='1' AND TIP='FC'

IF OBJECT_ID('tempdb..#pozconfc') IS NOT NULL
	DROP TABLE	#pozconfc
	
select top (0) p.Subunitate, p.Tip, p.Data, p.Contract, p.Tert, p.Cod, p.Numar_pozitie
	, p.Termen, p.Explicatii
into #pozconfc
from pozcon p

UPDATE pozcon SET 
--SELECT 
Termen=DATEADD(day,ISNULL(NULLIF([dbo].verificNumar(
	COALESCE((SELECT TOP 1 pfax.explicatii 
	FROM pozcon pfa INNER JOIN con fa ON fa.subunitate=pfa.subunitate AND fa.tip=pfa.tip AND fa.Data=pfa.Data AND fa.Tert=pfa.Tert 
			AND fa.Contract=pfa.Contract
		join pozcon pfax on pfax.subunitate='EXPAND' and pfax.tip =pfa.tip and pfax.data=pfa.data and pfax.contract=pfa.contract 
			and pfax.tert=pfa.tert and pfax.cod=pfa.cod and pfax.numar_pozitie=pfa.numar_pozitie
	WHERE pfa.Subunitate=pozcon.Subunitate AND pfa.Tip='FA' AND pfa.Tert=nomencl.Furnizor AND pfa.cod=pozcon.cod 
		/*AND (con.contract_coresp ='' OR pfa.contract=con.contract_coresp)*/
	ORDER BY pfa.subunitate, pfa.tip, pfa.Tert, ISNULL(NULLIF(pfa.Contract,con.contract_coresp),''), pfa.Data DESC)
		,(SELECT TOP 1 pr.valoare FROM proprietati pr WHERE pr.tip='NOMENCL' AND pr.cod=pozcon.cod AND pr.cod_proprietate='ATP' ORDER BY pr.valoare DESC)
		,px.explicatii,'')
	),0),30),pozcon.Data)
OUTPUT inserted.Subunitate,inserted.Tip,inserted.Data,inserted.Contract,inserted.Tert,inserted.Cod,inserted.Numar_pozitie
	,inserted.Termen, inserted.Explicatii
INTO #pozconfc
FROM pozcon 
	INNER JOIN con ON con.subunitate=pozcon.subunitate AND con.tip=pozcon.tip AND con.Data=pozcon.Data AND con.Tert=pozcon.Tert 
		AND con.Contract=pozcon.Contract
	INNER JOIN nomencl ON pozcon.Cod=nomencl.Cod
	LEFT JOIN pozcon px ON px.subunitate='EXPAND' and px.tip =pozcon.tip and px.data=pozcon.data 
			and px.contract=pozcon.contract and px.tert=pozcon.tert and px.cod=pozcon.cod and px.numar_pozitie=pozcon.numar_pozitie
	LEFT JOIN grupe ON grupe.Tip_de_nomenclator=nomencl.Tip AND grupe.Denumire=nomencl.Grupa
	LEFT JOIN terti ON terti.Subunitate=pozcon.Subunitate AND terti.Tert=nomencl.Furnizor
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
/*
select *
--*/ update n set termen=a.Termen, explicatii=a.Explicatii
from necesaraprov n 
	join pozaprov p on p.Tip='N' and p.Comanda_livrare=n.Numar and p.Data_comenzii=n.Data and p.Cod=n.Cod
	join #pozconfc a on a.Data=p.Data and a.Contract=p.Contract and a.Tert=p.Furnizor and a.Cod=p.Cod
	
	--UPDATE pozcon
	--SET Cant_aprobata=Cantitate
	--WHERE CURRENT OF coduriLivrFaraStoc 
/*
SELECT pozcon.cod
,(SELECT /*ISNULL(DATEDIFF(day,fa.Data,*/(SELECT MAX(t.termen) FROM Termene t WHERE t.Subunitate=fa.Subunitate 
			AND t.Tip=fa.Tip AND t.Data=fa.Data AND t.Tert=fa.Tert AND t.Contract=fa.Contract AND t.Cod=pozcon.cod)/*),fa.Scadenta)*/
		FROM con fa WHERE  fa.Tip='FA' AND fa.Tert=nomencl.Furnizor)
,DATEADD(day,ISNULL(NULLIF(
			(SELECT ISNULL(DATEDIFF(day,fa.Data,(SELECT MAX(t.termen) FROM Termene t WHERE t.Subunitate=fa.Subunitate 
			AND t.Tip=fa.Tip AND t.Data=fa.Data AND t.Tert=fa.Tert AND t.Contract=fa.Contract AND t.Cod=pozcon.cod)),fa.Scadenta)
		FROM con fa WHERE fa.Subunitate=pozcon.Subunitate AND fa.Tip='FA' AND fa.Tert=nomencl.Furnizor),0),30),pozcon.Data)
	,Cant_aprobata=Cantitate
	,Cant_disponibila=Cant_aprobata
	,Mod_de_plata=CONVERT(CHAR(8),Termen,112)
FROM pozcon INNER JOIN nomencl ON pozcon.Cod=nomencl.Cod
	LEFT JOIN grupe ON grupe.Tip_de_nomenclator=nomencl.Tip AND grupe.Denumire=nomencl.Grupa
	LEFT JOIN terti ON terti.Subunitate=pozcon.Subunitate AND terti.Tert=nomencl.Furnizor
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
		AND ABS(Cantitate-Cant_aprobata)>0.001
		*/