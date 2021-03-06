USE [TET]
GO
/****** Object:  StoredProcedure [yso].[CalculTermeneBK]    Script Date: 12/28/2011 17:27:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [yso].[CalculTermeneFC] 
--DECLARE
@Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME 
AS
--pun termen pe comanda livrare

DECLARE	@lRezStocBK bit, @cListaGestRezStocBK CHAR(200), @codLivr CHAR(30), @cantLivr FLOAT, @cantLibera FLOAT, @dTermenAprov DATETIME
	,@contrAprov CHAR(20), @cFurnAprov CHAR(13), @dataAprov DATETIME, @randuri INT
	
EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

--SET @Subunitate='1'
--SET @Tip='BK'
--SET @Contract='52'
--SET @Tert='12267509'
--SET @Data='12/20/2011'
-- select * from pozcon where contract='52'

IF OBJECT_ID('tempdb..##testetmp') <> NULL
DROP TABLE	##testetmp

UPDATE pozcon
SET Termen=DATEADD(day,ISNULL(NULLIF(
		(SELECT TOP 1 ISNULL(DATEDIFF(day,fa.Data,(SELECT MAX(t.termen) FROM Termene t WHERE t.Subunitate=pfa.Subunitate 
			AND t.Tip=pfa.Tip AND t.Data=pfa.Data AND t.Tert=pfa.Tert AND t.Contract=pfa.Contract AND t.Cod=pfa.cod)),fa.Scadenta)
		FROM pozcon pfa INNER JOIN con fa ON fa.subunitate=pfa.subunitate AND fa.tip=pfa.tip AND fa.Data=pfa.Data 
			AND fa.Tert=pfa.Tert AND fa.Contract=pfa.Contract
		WHERE pfa.Subunitate=pozcon.Subunitate AND pfa.Tip='FA' AND pfa.Tert=pozcon.Tert AND pfa.cod=pozcon.cod
		ORDER BY pfa.subunitate, pfa.tip, pfa.Tert, pfa.Data DESC, pfa.Contract),0),30),pozcon.Data)
FROM pozcon 
	INNER JOIN nomencl ON pozcon.Cod=nomencl.Cod
	LEFT JOIN grupe ON grupe.Tip_de_nomenclator=nomencl.Tip AND grupe.Denumire=nomencl.Grupa
	LEFT JOIN terti ON terti.Subunitate=pozcon.Subunitate AND terti.Tert=nomencl.Furnizor
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
SET @randuri=@@ROWCOUNT
		
		
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