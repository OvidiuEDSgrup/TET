CREATE PROCEDURE [dbo].[CalculTermeneBK] 
--DECLARE
@Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME 
AS
--pun termen pe comanda livrare

DECLARE	@lRezStocBK bit, @cListaGestRezStocBK CHAR(200), @codLivr CHAR(30), @cantLivr FLOAT, @cantLibera FLOAT, @dTermenAprov DATETIME
	,@contrAprov CHAR(20), @cFurnAprov CHAR(13), @dataAprov DATETIME, @randuri INT
	
EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

SET @Subunitate='1'
SET @Tip='BK'
SET @Contract='52'
SET @Tert='12267509'
SET @Data='12/20/2011'
-- select * from pozcon where contract='52'

IF OBJECT_ID('tempdb..##testetmp') <> NULL
DROP TABLE	##testetmp

--daca am stoc acum pun ziua de azi, altfel le marchez cu termen 1900
UPDATE pozcon SET 
--SELECT cod,
Cant_aprobata=ISNULL((SELECT SUM(stoc) FROM stocuri s
		WHERE s.Subunitate=@Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 
			AND (CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';')>0 
				AND s.Contract=pozcon.Contract
				OR s.Cod_gestiune=pozcon.Factura AND s.Contract=pozcon.Contract
				OR s.Cod_gestiune=CONVERT(CHAR(20),pozcon.Factura) AND RTRIM(s.Contract)=''
				OR s.Contract=pozcon.Contract)
			AND s.Cod=pozcon.Cod),0)
--INTO ##testetmp	
FROM pozcon
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
SET @randuri=@@ROWCOUNT

UPDATE pozcon
SET Termen=CASE Cant_aprobata	
			WHEN 0 THEN ''
			ELSE GETDATE() END
	,Cant_aprobata= CASE WHEN Cant_aprobata>Cantitate THEN Cantitate ELSE Cant_aprobata END
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
SET @randuri=@@ROWCOUNT

--daca am pozitii legate dea de o comanda de aprovizionare aduc termenul cel mai tarziu de acolo, altfel las termenul neatins
UPDATE pozcon
SET Termen= pozaprovcomlivr.Termen
	,Cant_aprobata=CASE WHEN Cant_aprobata+Cant_comandata<= Cantitate THEN Cant_aprobata+Cant_comandata ELSE Cantitate END
FROM pozcon INNER JOIN
	(SELECT pozaprov.cod, MAX(Termen) AS Termen, SUM(pozaprov.Cant_comandata) AS Cant_comandata 
		FROM pozaprov INNER JOIN pozcon ca ON ca.Subunitate=@Subunitate AND ca.Tip='FC' 
			AND ca.Data=pozaprov.Data AND ca.Tert=pozaprov.Furnizor AND ca.Contract=pozaprov.Contract and ca.Cod=pozaprov.Cod
	WHERE pozaprov.Beneficiar=@Tert AND pozaprov.Data_comenzii=@Data AND pozaprov.Comanda_livrare=@Contract
	GROUP BY pozaprov.Cod) pozaprovcomlivr
	ON pozaprovcomlivr.cod=pozcon.cod 
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
	and Cant_aprobata<Cantitate 
SET @randuri=@@ROWCOUNT

--daca nu am stoc si nici nu este legata de o com de aprov atunci incerc sa leg pozitiile de o comanda de aprov existenta 
--si nelegata deja de alte comenzi de livrare

DECLARE coduriLivrFaraStoc CURSOR FOR 
	SELECT cod, Cantitate-cant_aprobata AS Cant_necesara FROM pozcon 
	WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
		AND Cant_aprobata<Cantitate

OPEN coduriLivrFaraStoc
FETCH NEXT FROM coduriLivrFaraStoc INTO @codLivr, @cantLivr
WHILE @@FETCH_STATUS=0
BEGIN
	DECLARE coduriAprovLibere CURSOR FOR
	SELECT pozcon.contract, pozcon.data, pozcon.Tert, pozcon.Termen ,pozcon.Cant_aprobata
		-ISNULL((SELECT SUM(Cant_comandata) FROM pozaprov WHERE pozaprov.Contract=pozcon.Contract AND pozaprov.Data=pozcon.Data 
			AND pozaprov.Furnizor=pozcon.Tert and pozaprov.cod=pozcon.cod AND pozaprov.tip='BK' AND pozaprov.Comanda_livrare<>'' 
			AND ABS(pozaprov.Cant_comandata)>0.001),0)
	FROM pozcon INNER JOIN con ON con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and con.data=pozcon.data 
		and con.tert=pozcon.tert and con.contract=pozcon.contract
	WHERE pozcon.cod=@codLivr AND pozcon.subunitate=@subunitate AND pozcon.tip='FC' AND con.stare<='1'
	ORDER BY pozcon.data
	
	OPEN coduriAprovLibere
	FETCH NEXT FROM coduriAprovLibere INTO @contrAprov, @dataAprov, @cFurnAprov, @dTermenAprov, @cantLibera
	
	WHILE @@FETCH_STATUS=0 AND ABS(@cantLibera)>0.001
	BEGIN
		UPDATE pozaprov
		SET Cant_comandata=Cant_comandata+CASE WHEN @cantLibera<=@cantLivr THEN @cantLibera ELSE @cantLivr END
		WHERE Contract=@contrAprov and Data=@dataAprov AND Furnizor=@cFurnAprov AND Cod=@codLivr AND Tip=@Tip
			AND Comanda_livrare=@Contract AND Data_comenzii=@Data AND Beneficiar=@Tert
		SET @randuri=@@ROWCOUNT
			
		IF @@ROWCOUNT<=0	
			INSERT INTO pozaprov --Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar
			(Contract,Data,Furnizor,Cod,Comanda_livrare,Data_comenzii,Beneficiar
			,Cant_comandata,Cant_receptionata,Cant_realizata,Tip)
			 VALUES
			(@contrAprov,@dataAprov,@cFurnAprov,@codLivr,@Contract,@Data,@Tert
			,CASE WHEN @cantLibera<=@cantLivr THEN @cantLibera ELSE @cantLivr END,0,0,@Tip)
		SET @randuri=@@ROWCOUNT
		
		UPDATE pozcon
		SET Cant_aprobata=Cant_aprobata+CASE WHEN @cantLibera<@cantLivr THEN @cantLibera ELSE @cantLivr END
			,Termen=CASE WHEN Termen<@dTermenAprov THEN @dTermenAprov ELSE Termen END
		WHERE CURRENT OF coduriAprovLibere
		SET @randuri=@@ROWCOUNT
			   
		FETCH NEXT FROM coduriAprovLibere INTO @contrAprov, @dataAprov, @cFurnAprov, @dTermenAprov, @cantLibera
	END
	CLOSE coduriAprovLibere
	DEALLOCATE coduriAprovLibere
	
FETCH NEXT FROM coduriLivrFaraStoc INTO @codLivr, @cantLivr
END
CLOSE coduriLivrFaraStoc
DEALLOCATE coduriLivrFaraStoc


-- daca inca mai am pozitii cu termenul necompletat trebuie sa pun :
-- daca furnizorul trecut la acel cod are contract se va trece ziua introducerii 
-- + campul scadenta de la contractul de tip FA de la acel tert din tabel con. 
-- Daca la acel cod nu are contract acel furnizor la termen pun ziua introducerii comenzii + 30 zile .

UPDATE pozcon
SET Termen=DATEADD(day,ISNULL(NULLIF(
		(SELECT TOP 1 ISNULL(DATEDIFF(day,fa.Data,(SELECT MAX(t.termen) FROM Termene t WHERE t.Subunitate=pfa.Subunitate 
			AND t.Tip=pfa.Tip AND t.Data=pfa.Data AND t.Tert=pfa.Tert AND t.Contract=pfa.Contract AND t.Cod=pfa.cod)),fa.Scadenta)
		FROM pozcon pfa INNER JOIN con fa ON fa.subunitate=pfa.subunitate AND fa.tip=pfa.tip AND fa.Data=pfa.Data 
			AND fa.Tert=pfa.Tert AND fa.Contract=pfa.Contract
		WHERE pfa.Subunitate=pozcon.Subunitate AND pfa.Tip='FA' AND pfa.Tert=nomencl.Furnizor AND pfa.cod=pozcon.cod
		ORDER BY pfa.subunitate, pfa.tip, pfa.Tert, pfa.Data DESC, pfa.Contract),0),25),pozcon.Data)
	,Cant_aprobata=Cantitate
	,Cant_disponibila=Cant_aprobata
	,Mod_de_plata=CONVERT(CHAR(8),Termen,112)
FROM pozcon INNER JOIN nomencl ON pozcon.Cod=nomencl.Cod
	LEFT JOIN grupe ON grupe.Tip_de_nomenclator=nomencl.Tip AND grupe.Denumire=nomencl.Grupa
	LEFT JOIN terti ON terti.Subunitate=pozcon.Subunitate AND terti.Tert=nomencl.Furnizor
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
		AND ABS(Cantitate-Cant_aprobata)>0.001
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
