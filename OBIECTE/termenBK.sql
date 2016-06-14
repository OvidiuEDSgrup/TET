
ALTER PROCEDURE yso.DefalcTermeneBK 
--DECLARE
@Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Tert CHAR(13), @Data DATETIME 
AS
--pun termen pe comanda livrare

DECLARE	@lRezStocBK bit, @cListaGestRezStocBK CHAR(200)
	,@Cod CHAR(30), @CantNecesara FLOAT, @CantRealizata FLOAT, @Stoc FLOAT, @TermenMaxim DATETIME, @CantComAprov FLOAT
	,@CantLibera FLOAT, @TermenAprov DATETIME,@contrAprov CHAR(20), @FurnAprov CHAR(13), @dataAprov DATETIME
	,@randuri INT
	
EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

--SET @Subunitate='1'
--SET @Tip='BK'
--SET @Contract='51'
--SET @Tert='RO14737011'
--SET @Data='12/20/2011'
-- select * from pozcon where contract='52'

IF OBJECT_ID('##testetmp') <> NULL
DROP TABLE	##testetmp

DELETE Termene
WHERE Subunitate=@Subunitate AND Tip=@Tip AND Contract=@Contract AND Tert=@Tert AND Data=@Data 

DECLARE pozComLivr CURSOR FOR 
SELECT pozcon.Cod, Cant_aprobata, Cant_realizata
,ISNULL((SELECT SUM(stoc) FROM stocuri s
		WHERE s.Subunitate=@Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 
			AND (CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';')>0 
				AND s.Contract=pozcon.Contract AND @lRezStocBK=1
				OR s.Cod_gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND s.Contract=pozcon.Contract
				OR s.Cod_gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND s.Contract=''
				OR s.Contract=pozcon.Contract)
			AND s.Cod=pozcon.Cod),0) AS Stoc
,DATEADD(day,ISNULL(NULLIF(
		(SELECT TOP 1 ISNULL(DATEDIFF(day,fa.Data,(SELECT MAX(t.termen) FROM Termene t WHERE t.Subunitate=pfa.Subunitate 
			AND t.Tip=pfa.Tip AND t.Data=pfa.Data AND t.Tert=pfa.Tert AND t.Contract=pfa.Contract AND t.Cod=pfa.cod)),fa.Scadenta)
		FROM pozcon pfa INNER JOIN con fa ON fa.subunitate=pfa.subunitate AND fa.tip=pfa.tip AND fa.Data=pfa.Data 
			AND fa.Tert=pfa.Tert AND fa.Contract=pfa.Contract
		WHERE pfa.Subunitate=pozcon.Subunitate AND pfa.Tip='FA' AND pfa.Tert=nomencl.Furnizor AND pfa.cod=pozcon.cod
		ORDER BY pfa.subunitate, pfa.tip, pfa.Tert, pfa.Data DESC, pfa.Contract),0),30),pozcon.Data) AS TermenMaxim
FROM pozcon INNER JOIN nomencl ON nomencl.cod=pozcon.cod
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 

OPEN pozComLivr
FETCH NEXT FROM pozComLivr INTO @Cod, @CantNecesara, @CantRealizata, @Stoc, @TermenMaxim

WHILE @@FETCH_STATUS<>-1 AND ABS(@CantNecesara)>0.001
BEGIN
	--daca am stoc acum pun ziua de azi, altfel le marchez cu termen 1900
	--defalc cantitatea pe termene si scriu sursa

	IF @Stoc>0
	BEGIN
		INSERT Termene
		(Subunitate,Tip,Contract,Tert,Cod,Data,Termen,Cantitate
		,Explicatii
		,Cant_realizata,Pret,Val1,Val2,Data1,Data2)
		VALUES 
		(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@Data,CASE WHEN @Stoc<@CantNecesara THEN @Stoc ELSE @CantNecesara END
		,RTRIM(CONVERT(CHAR(20),CASE WHEN @Stoc<@CantNecesara THEN @Stoc ELSE @CantNecesara END))+' din Stoc '
		,0,0,0,0,'','')
		
		SET @CantNecesara=@CantNecesara-CASE WHEN @Stoc<@CantNecesara THEN @Stoc ELSE @CantNecesara END
	END
	
	--daca am pozitii legate de o comanda de aprovizionare aduc termenul cel mai tarziu de acolo, altfel las termenul neatins
	IF ABS(@CantNecesara)<0.001 GOTO NEXT_pozComLivr
	
	DECLARE cursorTermenePozAprov CURSOR FOR
	SELECT Termen, SUM(pozaprov.Cant_comandata) AS Cant_comandata
	FROM pozaprov INNER JOIN pozcon ca ON ca.Subunitate=@Subunitate AND ca.Tip='FC' 
		AND ca.Data=pozaprov.Data AND ca.Tert=pozaprov.Furnizor AND ca.Contract=pozaprov.Contract and ca.Cod=pozaprov.Cod
	WHERE pozaprov.Beneficiar=@Tert AND pozaprov.Data_comenzii=@Data AND pozaprov.Comanda_livrare=@Contract AND pozaprov.Cod=@Cod
	GROUP BY ca.Termen
	
	OPEN cursorTermenePozAprov
	FETCH NEXT FROM cursorTermenePozAprov INTO @TermenAprov, @CantComAprov
	
	WHILE @@FETCH_STATUS<>-1 AND ABS(@CantNecesara)>0.001
	BEGIN
		UPDATE Termene
		SET Cantitate=t.Cantitate+CASE WHEN @CantComAprov<@CantNecesara THEN @CantComAprov ELSE @CantNecesara END
			,Explicatii=RTRIM(ISNULL(NULLIF(t.Explicatii,'')+'+',''))
				+RTRIM(CONVERT(CHAR(20),t.Cantitate+CASE WHEN @CantComAprov<@CantNecesara THEN @CantComAprov ELSE @CantNecesara END))
				+' din Aprovizionare '
		FROM Termene t 
		WHERE t.Subunitate=@Subunitate AND t.Tip=@Tip AND t.Contract=@Contract AND t.Tert=@Tert AND t.Data=@Data 
			and t.Cod=@Cod and t.Termen=@TermenAprov
		
		IF @@ROWCOUNT<=0
			INSERT Termene
			(Subunitate,Tip,Contract,Tert,Cod,Data,Termen,Cantitate
			,Explicatii
			,Cant_realizata,Pret,Val1,Val2,Data1,Data2)
			VALUES
			(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@TermenAprov,CASE WHEN @CantComAprov<@CantNecesara THEN @CantComAprov ELSE @CantNecesara END
			,RTRIM(CONVERT(CHAR(20),CASE WHEN @CantComAprov<@CantNecesara THEN @CantComAprov ELSE @CantNecesara END))
				+' din Aprovizionare '
			,0,0,0,0,'','')
		
		SET @CantNecesara=@CantNecesara-CASE WHEN @CantComAprov<@CantNecesara THEN @CantComAprov ELSE @CantNecesara END
		FETCH NEXT FROM cursorTermenePozAprov INTO @TermenAprov, @CantComAprov
	END
	CLOSE cursorTermenePozAprov
	DEALLOCATE cursorTermenePozAprov


	--daca nu am stoc si nici nu este legata de o com de aprov atunci incerc sa leg pozitiile de o comanda de aprov existenta 
	--si nelegata deja de alte comenzi de livrare
	IF ABS(@CantNecesara)<0.001 GOTO NEXT_pozComLivr

	DECLARE coduriAprovLibere CURSOR FOR
	SELECT pozcon.contract, pozcon.data, pozcon.Tert, pozcon.Termen, pozcon.Cant_aprobata
		-ISNULL((SELECT SUM(Cant_comandata) FROM pozaprov WHERE pozaprov.Contract=pozcon.Contract AND pozaprov.Data=pozcon.Data 
			AND pozaprov.Furnizor=pozcon.Tert and pozaprov.cod=pozcon.cod AND pozaprov.tip='BK' AND pozaprov.Comanda_livrare<>'' 
			AND ABS(pozaprov.Cant_comandata)>0.001 AND ABS(pozaprov.Cant_realizata)<0.001),0)
	FROM pozcon INNER JOIN con ON con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and con.data=pozcon.data 
		and con.tert=pozcon.tert and con.contract=pozcon.contract
	WHERE pozcon.cod=@Cod AND pozcon.subunitate=@subunitate AND pozcon.tip='FC' AND con.stare<='1'
	ORDER BY pozcon.data
	
	OPEN coduriAprovLibere
	FETCH NEXT FROM coduriAprovLibere INTO @contrAprov, @dataAprov, @FurnAprov, @TermenAprov, @CantLibera
			
	WHILE @@FETCH_STATUS<>-1 AND ABS(@CantNecesara)>0.001 
	BEGIN
		IF ABS(@CantLibera)<0.001 GOTO NEXT_coduriAprovLibere
			
		UPDATE pozaprov
		SET Cant_comandata=Cant_comandata+CASE WHEN @CantLibera<@CantNecesara THEN @CantLibera ELSE @CantNecesara END
		WHERE Contract=@contrAprov and Data=@dataAprov AND Furnizor=@FurnAprov AND Cod=@Cod AND Tip=@Tip
			AND Comanda_livrare=@Contract AND Data_comenzii=@Data AND Beneficiar=@Tert
			
		IF @@ROWCOUNT<=0	
			INSERT INTO pozaprov --Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar
			(Contract,Data,Furnizor,Cod,Comanda_livrare,Data_comenzii,Beneficiar
			,Cant_comandata,Cant_receptionata,Cant_realizata,Tip)
			 VALUES
			(@contrAprov,@dataAprov,@FurnAprov,@Cod,@Contract,@Data,@Tert
			,CASE WHEN @CantLibera<@CantNecesara THEN @CantLibera ELSE @CantNecesara END,0,0,@Tip)
		SET @randuri=@@ROWCOUNT
		
		UPDATE Termene
		SET Cantitate=t.Cantitate+CASE WHEN @CantLibera<@CantNecesara THEN @CantLibera ELSE @CantNecesara END
			,Explicatii=LEFT(RTRIM(ISNULL(NULLIF(t.Explicatii,'')+'+',''))
				+RTRIM(CONVERT(CHAR(20),t.Cantitate+CASE WHEN @CantLibera<@CantNecesara THEN @CantLibera ELSE @CantNecesara END))
				+' din Aprovizionare ',200)
		FROM Termene t 
		WHERE t.Subunitate=@Subunitate AND t.Tip=@Tip AND t.Contract=@Contract AND t.Tert=@Tert AND t.Data=@Data 
			and t.Cod=@Cod and t.Termen=@TermenAprov
		
		IF @@ROWCOUNT<=0
			INSERT Termene
			(Subunitate,Tip,Contract,Tert,Cod,Data,Termen,Cantitate
			,Explicatii
			,Cant_realizata,Pret,Val1,Val2,Data1,Data2)
			VALUES
			(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@TermenAprov,CASE WHEN @CantLibera<@CantNecesara THEN @CantLibera ELSE @CantNecesara END
			,RTRIM(CONVERT(CHAR(20),CASE WHEN @CantLibera<@CantNecesara THEN @CantLibera ELSE @CantNecesara END))
				+' din Aprovizionare '
			,0,0,0,0,'','')	
			
		NEXT_coduriAprovLibere:	   
		SET @CantNecesara=@CantNecesara-CASE WHEN @CantLibera<@CantNecesara THEN @CantLibera ELSE @CantNecesara END
		FETCH NEXT FROM coduriAprovLibere INTO @contrAprov, @dataAprov, @FurnAprov, @TermenAprov, @CantLibera
	END
	CLOSE coduriAprovLibere
	DEALLOCATE coduriAprovLibere

	NEXT_pozComLivr:
	--dupa ce am terminat defalcarea pe termene actualizez termenele si in pozcon
	IF ABS(@CantNecesara)>0.001
		INSERT Termene
		(Subunitate,Tip,Contract,Tert,Cod,Data,Termen,Cantitate
		,Explicatii
		,Cant_realizata,Pret,Val1,Val2,Data1,Data2)
		VALUES
		(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@TermenMaxim,@CantNecesara
		,RTRIM(CONVERT(CHAR(20),@CantNecesara))
			+' din Contracte'
		,0,0,0,0,'','')
			
	UPDATE pozcon
	SET Termen=ISNULL((SELECT MAX(Termen) FROM Termene t WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
			and p.Contract=t.Contract and p.Cod=t.Cod), @TermenMaxim)
		/*,Explicatii=LEFT(REPLACE((SELECT RTRIM(t.Explicatii)+' la '+LTRIM(RTRIM(CONVERT(CHAR(20),t.Termen,103)))+' ' AS [data()] FROM Termene t 
			WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
		and p.Contract=t.Contract and p.Cod=t.Cod ORDER BY t.Termen FOR XML PATH('')),'  ',CHAR(10)+CHAR(13)),200)*/
	FROM pozcon p
	WHERE CURRENT OF pozComLivr
	FETCH NEXT FROM pozComLivr INTO @Cod, @CantNecesara, @CantRealizata, @Stoc, @TermenMaxim
	
END
CLOSE pozComLivr
DEALLOCATE pozComLivr

-- daca inca mai am pozitii cu termenul necompletat trebuie sa pun :
-- daca furnizorul trecut la acel cod are contract se va trece ziua introducerii 
-- + campul scadenta de la contractul de tip FA de la acel tert din tabel con. 
-- Daca la acel cod nu are contract acel furnizor la termen pun ziua introducerii comenzii + 30 zile .
/*
UPDATE Termene
SET Cantitate=t.Cantitate+p.Cant_aprobata
	,Explicatii=RTRIM(ISNULL(NULLIF(t.Explicatii,'')+'+',''))+RTRIM(CONVERT(CHAR(20),p.Cant_aprobata))+' din Detalii comenzi aprovizionare '
FROM Termene t INNER JOIN pozcon p ON p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
	and p.Contract=t.Contract and p.Cod=t.Cod and p.Termen=t.Termen
WHERE p.Subunitate=@Subunitate AND p.Tip=@Tip AND p.Contract=@Contract AND p.Tert=@Tert AND p.Data=@Data 
	and p.Cant_aprobata>0 and p.Cant_aprobata<p.Cantitate
	
INSERT Termene
SELECT Subunitate,Tip,Contract,Tert,Cod,Data,@TermenMaxim,Cant_aprobata
,RTRIM(CONVERT(CHAR(20),p.Cant_aprobata))+' din Contract furnizor'
,0,0,0,0,'',''
FROM pozcon p 
WHERE p.Subunitate=@Subunitate AND p.Tip=@Tip AND p.Contract=@Contract AND p.Tert=@Tert AND p.Data=@Data AND p.Cod=@Cod
	and not exists (SELECT 1 FROM Termene t WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
		and p.Contract=t.Contract and p.Cod=t.Cod and p.Termen=t.Termen)
*/
			

GO
/*
DECLARE test  CURSOR SCROLL DYNAMIC FOR
SELECT /*subunitate,tip,data,tert,contract,*/cod, cantitate ,(SELECT SUM (cantitate) FROM pozcon p WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
	and p.Contract=t.Contract and p.Cod=t.Cod and p.Termen=t.Termen)
from termene t
WHERE TIP='BK'
--group by subunitate,tip,data,tert,contract,cod
for update

OPEN test
FETCH NEXT FROM test --INTO @subunitate,@tip,@data,@tert,@contract,@Cod,@CantLIVR

WHILE @@FETCH_STATUS=0
BEGIN
--UPDATE Termene
--SET Cantitate=Cantitate+1
--WHERE CURRENT OF test
--FETCH PRIOR FROM test
FETCH NEXT FROM TEST --INTO @subunitate,@tip,@data,@tert,@contract,@Cod,@CantLIVR
END
FETCH PRIOR FROM test
FETCH PRIOR FROM test

DECLARE @Report CURSOR

exec sp_cursor_list @cursor_return=@Report OUTPUT,@cursor_scope=3
WHILE @@FETCH_STATUS=0
BEGIN
--UPDATE Termene
--SET Cantitate=Cantitate+1
--WHERE CURRENT OF test
--FETCH PRIOR FROM test
FETCH NEXT FROM @Report --INTO @subunitate,@tip,@data,@tert,@contract,@Cod,@CantLIVR
END
CLOSE test
DEALLOCATE test
--*/