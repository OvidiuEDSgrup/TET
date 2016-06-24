CREATE PROCEDURE [dbo].DefalcTermeneBK @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Data DATETIME, @Tert CHAR(13) AS

--DECLARE @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Data DATETIME, @Tert CHAR(13)
--SELECT TOP 1 
--@Subunitate='1'
--,@Tip='BK'
--,@Contract=Contract
--,@Tert=Tert
--,@Data=data
--FROM pozcon where tip='bk' and Contract='9820097'

-- select * from pozcon where contract='52'
--pun termen pe comanda livrare

DECLARE	@lRezStocBK bit, @cListaGestRezStocBK CHAR(200)
	,@Cod CHAR(30), @CantComLivr FLOAT, @CantAprobLivr FLOAT, @CantRealizataBK FLOAT, @termenComLivr DATETIME, @termenAprobLivr CHAR(8)
	,@StocGest FLOAT, @StocDisponibil FLOAT, @StocRezervat FLOAT, @TermenMaxim DATETIME, @CantComPozAprov FLOAT
	,@CantLibera FLOAT, @TermenAprov DATETIME,@contrAprov CHAR(20), @FurnAprov CHAR(13), @dataAprov DATETIME
	,@cUM CHAR(1), @nZiScad SMALLINT, @amDatTermene smallint, @amTermene smallint, @dataCurenta date
	,@CantNecesara FLOAT, @CantDescStoc FLOAT, @CantDescAprov FLOAT, @CantDescContr FLOAT, @termenDescarcare DATETIME
	,@randuri INT, @transferuri float, @avize float, @alteiesiri float, @cantRealizTotal float, @termenFinal datetime

SET @dataCurenta=CONVERT (date, GETDATE())
EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

IF OBJECT_ID('tempdb..#codGestComLivr') IS NOT NULL
DROP TABLE	#codGestComLivr

SELECT Cod, MAX(Contract) AS Contract, MAX(ISNULL(NULLIF(Punct_livrare,''), Factura)) AS Gestiune, SUM(Cant_aprobata) AS Cant_aprobata
INTO #codGestComLivr
FROM pozcon 
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
GROUP BY Cod

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #codGestComLivr (Cod)
CREATE UNIQUE NONCLUSTERED INDEX Contract ON #codGestComLivr (Cod,Contract)
CREATE UNIQUE NONCLUSTERED INDEX Gestiune ON #codGestComLivr (Cod,Gestiune)

IF OBJECT_ID('tempdb..#stocGestiune') IS NOT NULL
DROP TABLE	#stocGestiune

SELECT s.cod, SUM(Stoc) AS StocGest
INTO #stocGestiune
FROM dbo.stocuri s INNER JOIN #codGestComLivr c ON c.Cod=s.Cod
WHERE s.Subunitate=@Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 
	AND (s.Cod_gestiune=c.Gestiune AND s.Contract=c.Contract
		OR s.Cod_gestiune=c.Gestiune AND s.Contract=''
		OR CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';900;')>0 AND s.Contract=''
		OR s.Contract=c.Contract)
GROUP BY s.Cod

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #stocGestiune (Cod)

IF OBJECT_ID('tempdb..#stocRezervat') IS NOT NULL
DROP TABLE	#stocRezervat

SELECT s.Contract, s.cod, SUM(Stoc) AS StocRezervat
INTO #stocRezervat
FROM dbo.stocuri s 
INNER JOIN #codGestComLivr c ON c.Cod=s.Cod
INNER JOIN pozcon p ON p.Subunitate=@Subunitate and p.Tip=@Tip and p.Contract=s.Contract
	and c.Cod=p.Cod and c.Gestiune=ISNULL(NULLIF(p.Punct_livrare,''), p.Factura)
INNER JOIN con ON con.Subunitate=p.Subunitate and con.Tip=p.Tip and con.Contract=p.Contract and con.Data=p.Data and con.Tert=p.Tert
WHERE s.Subunitate=@Subunitate AND s.Tip_gestiune NOT IN ('F','T') AND s.Stoc>0.001 
AND (@lRezStocBK=1 AND CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';900;')>0 AND s.Contract=p.Contract)
GROUP BY s.Contract, s.Cod

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #stocRezervat (Contract,Cod)

IF OBJECT_ID('tempdb..#cantAprobAltele') IS NOT NULL
DROP TABLE	#cantAprobAltele

SELECT p.Cod,p.Contract,
dbo.valoare_maxima(SUM(dbo.valoare_maxima(p.Cant_aprobata-(p.Cant_realizata+ISNULL(s.StocRezervat,0)),0,null))
-MAX(c.Cant_aprobata),0,null) AS Cant_aprobata_altele
INTO #cantAprobAltele
FROM pozcon p INNER JOIN #codGestComLivr c ON c.Cod=p.Cod and c.Gestiune=ISNULL(NULLIF(p.Punct_livrare,''), p.Factura)
	INNER JOIN con ON con.Subunitate=p.Subunitate and con.Tip=p.Tip and con.Contract=p.Contract and con.Data=p.Data and con.Tert=p.Tert 
	LEFT JOIN #stocRezervat s ON s.Contract=p.Contract and s.Cod=p.Cod
WHERE p.Subunitate=@Subunitate and p.Tip='BK' 
GROUP BY p.Cod,p.Contract

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #cantAprobAltele (Cod,Contract)

IF OBJECT_ID('tempdb..#cantAprobAlte') IS NOT NULL
	DROP TABLE	#cantAprobAlte

SELECT p.Cod,
dbo.valoare_maxima(SUM(dbo.valoare_maxima(p.Cant_aprobata-(p.Cant_realizata+ISNULL(s.StocRezervat,0)),0,null))
-MAX(c.Cant_aprobata),0,null) AS Cant_aprobata_altele
INTO #cantAprobAlte
FROM pozcon p INNER JOIN #codGestComLivr c ON c.Cod=p.Cod and c.Gestiune=ISNULL(NULLIF(p.Punct_livrare,''), p.Factura) 
	INNER JOIN con ON con.Subunitate=p.Subunitate and con.Tip=p.Tip and con.Contract=p.Contract and con.Data=p.Data and con.Tert=p.Tert
	LEFT JOIN #stocRezervat s ON s.Contract=p.Contract and s.Cod=p.Cod
WHERE p.Subunitate=@Subunitate and p.Tip='BK' 
GROUP BY p.Cod

CREATE UNIQUE NONCLUSTERED INDEX Unic ON #cantAprobAlte (Cod)

DECLARE pozComLivr CURSOR FOR 
SELECT pozcon.Cod, pozcon.Cantitate, pozcon.Termen, pozcon.Cant_aprobata, pozcon.Mod_de_plata AS Termen_aprobat, pozcon.Cant_realizata
,pozcon.UM AS Confirmat,pozcon.Zi_scadenta_din_luna AS Reconfirmat
,ISNULL((select top 1 1 from termene t where pozcon.Subunitate=t.Subunitate AND pozcon.Tip=t.Tip AND pozcon.Data=t.Data and pozcon.Tert=t.Tert 
	and pozcon.Contract=t.Contract and pozcon.Cod=t.Cod),0) AS amTermen
,dbo.valoare_maxima(ISNULL(s.StocGest,0)-c.Cant_aprobata_altele,0,null) AS Stoc_disponibil
,ISNULL(r.StocRezervat,0) AS StocRezervat
,DATEADD(day,ISNULL(NULLIF([dbo].verificNumar(
	COALESCE((SELECT TOP 1 pfax.explicatii 
	FROM pozcon pfa INNER JOIN con fa ON fa.subunitate=pfa.subunitate AND fa.tip=pfa.tip AND fa.Data=pfa.Data AND fa.Tert=pfa.Tert 
			AND fa.Contract=pfa.Contract
		join pozcon pfax on pfax.subunitate='EXPAND' and pfax.tip =pfa.tip and pfax.data=pfa.data and pfax.contract=pfa.contract 
			and pfax.tert=pfa.tert and pfax.cod=pfa.cod and pfax.numar_pozitie=pfa.numar_pozitie
	WHERE pfa.Subunitate=pozcon.Subunitate AND pfa.Tip='FA' AND pfa.Tert=nomencl.Furnizor AND pfa.cod=pozcon.cod
	ORDER BY pfa.subunitate, pfa.tip, pfa.Tert, pfa.Data DESC, pfa.Contract)
		,(SELECT TOP 1 pr.valoare FROM proprietati pr WHERE pr.tip='NOMENCL' AND pr.cod=pozcon.cod AND pr.cod_proprietate='ATP' ORDER BY pr.valoare DESC)
		,px.explicatii,'')
	),0),30),pozcon.Data) AS TermenMaxim
,ISNULL((select SUM(p.cantitate)
from pozdoc p 
WHERE p.Subunitate=pozcon.Subunitate and p.Tip='TE' and p.Factura=pozcon.Contract 
	and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura) AND p.Cod=pozcon.Cod 
	AND par.Val_logica=1 AND CHARINDEX(';'+RTRIM(p.Gestiune_primitoare)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0 
	AND p.cantitate>0 and p.stare not in ('4', '6')),0) AS Transferuri
,ISNULL((select SUM(p.cantitate)
	from pozdoc p where p.Subunitate=pozcon.Subunitate and p.Tip='AP' and p.Contract=pozcon.Contract 
		--and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura)
		and p.Cod=pozcon.cod and p.cantitate>0),0) AS Avize
,ISNULL((select SUM(p.cantitate)
	from pozdoc p where p.Subunitate=pozcon.Subunitate and p.Tip='AE' and p.grupa=pozcon.Contract 
		--and p.Gestiune=ISNULL(NULLIF(pozcon.Punct_livrare,''), pozcon.Factura)
		and p.Cod=pozcon.cod and p.cantitate>0),0) AS AlteIesiri
FROM pozcon INNER JOIN nomencl ON nomencl.cod=pozcon.cod
	LEFT JOIN pozcon px ON px.subunitate='EXPAND' and px.tip =pozcon.tip and px.data=pozcon.data 
			and px.contract=pozcon.contract and px.tert=pozcon.tert and px.cod=pozcon.cod and px.numar_pozitie=pozcon.numar_pozitie 
	LEFT JOIN #stocGestiune s ON s.cod=pozcon.cod
	LEFT JOIN #cantAprobAlte c ON c.cod=pozcon.cod
	LEFT JOIN #stocRezervat r ON r.contract=pozcon.contract and r.Cod=pozcon.Cod
	LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
WHERE pozcon.Subunitate=@Subunitate AND pozcon.Tip=@Tip AND pozcon.Contract=@Contract AND pozcon.Tert=@Tert AND pozcon.Data=@Data 
FOR UPDATE OF pozcon.Termen,pozcon.Cant_aprobata,pozcon.Mod_de_plata,pozcon.UM,pozcon.Zi_scadenta_din_luna

OPEN pozComLivr
FETCH NEXT FROM pozComLivr INTO @Cod, @CantComLivr, @termenComLivr, @CantAprobLivr, @termenAprobLivr, @CantRealizataBK
	,@cUM, @nZiScad, @amTermene, @StocDisponibil, @StocRezervat, @TermenMaxim, @transferuri, @avize, @alteiesiri

WHILE @@FETCH_STATUS<>-1 --AND @CantComLivr>0.001
BEGIN
	IF @Cod='HP20SLO' 
		PRINT 'STOP'
		
	IF @CantComLivr<=0 GOTO NEXT_pozComLivr
	
	--daca am stoc acum pun ziua de azi, altfel le marchez cu termen 1900
	--defalc cantitatea pe termene si scriu sursa
	SET @amDatTermene=CASE @amTermene WHEN 1 THEN 1 ELSE CASE @nZiScad WHEN 0 THEN 0 ELSE 1 END END

	IF @amDatTermene=1 --and @nZiScad=1
		DELETE Termene
		WHERE Subunitate=@Subunitate AND Tip=@Tip AND Contract=@Contract AND Tert=@Tert AND Data=@Data and cod=@Cod
	
	SET @cantRealizTotal=dbo.valoare_maxima(@StocRezervat+@CantRealizataBK,dbo.valoare_maxima(@transferuri,@avize+@alteiesiri,null),null)
	
	SET @CantNecesara=@CantComLivr-@cantRealizTotal
	SET @CantDescStoc=0
	SET @termenDescarcare=@dataCurenta 
	
	--IF @StocDisponibil>=0.001
	SET @CantDescStoc=@cantRealizTotal
		+CASE WHEN @StocDisponibil<@CantNecesara THEN @StocDisponibil ELSE @CantNecesara END

	IF @amDatTermene=1
	BEGIN
		SET @CantAprobLivr=CASE 
			WHEN @CantAprobLivr<@cantRealizTotal THEN @cantRealizTotal ELSE @CantAprobLivr END
		IF @nZiScad<1
		BEGIN
			SET @termenDescarcare=@termenComLivr
			SET @CantDescStoc=CASE WHEN @CantAprobLivr<@CantDescStoc THEN @CantAprobLivr ELSE @CantDescStoc END
		END		
		--CASE ISDATE(@termenAprobLivr) WHEN 1 THEN CONVERT(DATE,@termenAprobLivr) ELSE @termenDescarcare END
	END
	
	IF @CantDescStoc>=0.001
		INSERT Termene
		(Subunitate,Tip,Contract,Tert,Cod,Data,Termen,Cantitate
		,Explicatii
		,Cant_realizata,Pret,Val1,Val2,Data1,Data2)
		VALUES 
		(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@termenDescarcare,@CantDescStoc
		,RTRIM(CONVERT(CHAR(20),@CantDescStoc))+' din Stoc '
		,0,0,0,0,'','')
	
	SET @CantNecesara=@CantNecesara-isnull(@CantDescStoc,0)
	
	--daca am pozitii legate de o comanda de aprovizionare aduc termenul cel mai tarziu de acolo, altfel las termenul neatins
	IF @CantNecesara<0.001 or 1=1 GOTO FINAL_pozComLivr
	
	DECLARE cursorTermenePozAprov CURSOR FOR
	SELECT Termen, SUM(pozaprov.Cant_comandata) AS Cant_comandata
	FROM pozaprov INNER JOIN pozcon ca ON ca.Subunitate=@Subunitate AND ca.Tip='FC' 
		AND ca.Data=pozaprov.Data AND ca.Tert=pozaprov.Furnizor AND ca.Contract=pozaprov.Contract and ca.Cod=pozaprov.Cod
	WHERE pozaprov.Beneficiar=@Tert AND pozaprov.Data_comenzii=@Data AND pozaprov.Comanda_livrare=@Contract AND pozaprov.Cod=@Cod
	GROUP BY ca.Termen
	
	OPEN cursorTermenePozAprov
	FETCH NEXT FROM cursorTermenePozAprov INTO @TermenAprov, @CantComPozAprov
	
	WHILE @@FETCH_STATUS<>-1 AND @CantNecesara>=0.001
	BEGIN
		SET @CantDescAprov=CASE WHEN @CantComPozAprov<@CantNecesara THEN @CantComPozAprov ELSE @CantNecesara END
		
		UPDATE Termene
		SET Cantitate=t.Cantitate+@CantDescAprov
			,Explicatii=LEFT(RTRIM(ISNULL(NULLIF(t.Explicatii,'')+'(+)',''))
				+RTRIM(CONVERT(CHAR(20),@CantDescAprov))
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
			(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@TermenAprov,@CantDescAprov
			,RTRIM(CONVERT(CHAR(20),@CantDescAprov))
				+' din Aprovizionare '
			,0,0,0,0,'','')
		
		SET @CantNecesara=@CantNecesara-isnull(@CantDescAprov,0)
		
		FETCH NEXT FROM cursorTermenePozAprov INTO @TermenAprov, @CantComPozAprov
	END
	CLOSE cursorTermenePozAprov
	DEALLOCATE cursorTermenePozAprov


	--daca nu am stoc si nici nu este legata de o com de aprov atunci incerc sa leg pozitiile de o comanda de aprov existenta 
	--si nelegata deja de alte comenzi de livrare
	IF @CantNecesara<0.001 or 1=1 GOTO FINAL_pozComLivr

	DECLARE coduriAprovLibere CURSOR FOR
	SELECT pozcon.contract, pozcon.data, pozcon.Tert, pozcon.Termen, pozcon.Cant_aprobata
		-ISNULL((SELECT SUM(Cant_comandata) FROM pozaprov WHERE pozaprov.Contract=pozcon.Contract AND pozaprov.Data=pozcon.Data 
			AND pozaprov.Furnizor=pozcon.Tert and pozaprov.cod=pozcon.cod AND pozaprov.tip='BK' AND pozaprov.Comanda_livrare<>'' 
			AND pozaprov.Cant_comandata>=0.001),0) AS Cant_libera
	FROM pozcon INNER JOIN con ON con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and con.data=pozcon.data 
		and con.tert=pozcon.tert and con.contract=pozcon.contract
	WHERE pozcon.cod=@Cod AND pozcon.subunitate=@subunitate AND pozcon.tip='FC' and pozcon.Termen>@data 
		and pozcon.Data<=@data --AND con.stare<='1'
		AND NOT EXISTS (SELECT 1 FROM pozcon p WHERE p.subunitate=pozcon.subunitate and p.tip=pozcon.tip 
			and p.contract=pozcon.contract and p.data=pozcon.data and p.tert=pozcon.tert and ABS(pozcon.cant_realizata)>=0.001)
	ORDER BY pozcon.data
	
	OPEN coduriAprovLibere
	FETCH NEXT FROM coduriAprovLibere INTO @contrAprov, @dataAprov, @FurnAprov, @TermenAprov, @CantLibera
			
	WHILE @@FETCH_STATUS<>-1 AND @CantNecesara>=0.001 
	BEGIN
		IF @CantLibera<0.001 GOTO NEXT_coduriAprovLibere
		
		SET @CantDescAprov=CASE WHEN @CantLibera<@CantNecesara THEN @CantLibera ELSE @CantNecesara END
			
		UPDATE pozaprov
		SET Cant_comandata=Cant_comandata+@CantDescAprov
		WHERE Contract=@contrAprov and Data=@dataAprov AND Furnizor=@FurnAprov AND Cod=@Cod AND Tip=@Tip
			AND Comanda_livrare=@Contract AND Data_comenzii=@Data AND Beneficiar=@Tert
			
		IF @@ROWCOUNT<=0 AND (@amDatTermene=0 or @nZiScad=1) 	
			INSERT INTO pozaprov --Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar
			(Contract,Data,Furnizor,Cod,Comanda_livrare,Data_comenzii,Beneficiar
			,Cant_comandata,Cant_receptionata,Cant_realizata,Tip)
			 VALUES
			(@contrAprov,@dataAprov,@FurnAprov,@Cod,@Contract,@Data,@Tert
			,@CantDescAprov,0,0,@Tip)
		
		UPDATE Termene
		SET Cantitate=t.Cantitate+@CantDescAprov
			,Explicatii=LEFT(RTRIM(ISNULL(NULLIF(t.Explicatii,'')+'(+)',''))
				+RTRIM(CONVERT(CHAR(20),@CantDescAprov))
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
			(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@TermenAprov,@CantDescAprov
			,RTRIM(CONVERT(CHAR(20),@CantDescAprov))
				+' din Aprovizionare '
			,0,0,0,0,'','')	
			
		NEXT_coduriAprovLibere:	   
		SET @CantNecesara=@CantNecesara-isnull(@CantDescAprov,0)
		FETCH NEXT FROM coduriAprovLibere INTO @contrAprov, @dataAprov, @FurnAprov, @TermenAprov, @CantLibera
	END
	CLOSE coduriAprovLibere
	DEALLOCATE coduriAprovLibere

	FINAL_pozComLivr:
	
	--if @Cod='5243G015004000'
	--	PRINT 'STOP'
	
	SET @termenFinal=CASE WHEN @amDatTermene=0 OR @nZiScad=1 THEN @TermenMaxim
		ELSE CASE WHEN @termenComLivr>@TermenMaxim THEN @termenComLivr ELSE @TermenMaxim END END
	
	IF @CantNecesara<0.001 OR @amDatTermene=1 AND @nZiScad=0 AND @cUM='' GOTO UPDATE_pozComLivr
	
	UPDATE Termene
	SET Cantitate=t.Cantitate+@CantNecesara
		,Explicatii=LEFT(RTRIM(ISNULL(NULLIF(t.Explicatii,'')+'(+)',''))
			+RTRIM(CONVERT(CHAR(20),@CantNecesara))
			+' din Contracte aprov furnizor',200)
	FROM Termene t 
	WHERE t.Subunitate=@Subunitate AND t.Tip=@Tip AND t.Contract=@Contract AND t.Tert=@Tert AND t.Data=@Data 
		and t.Cod=@Cod and t.Termen=@termenFinal

	IF @@ROWCOUNT<=0
		INSERT Termene
		(Subunitate,Tip,Contract,Tert,Cod,Data,Termen,Cantitate
		,Explicatii
		,Cant_realizata,Pret,Val1,Val2,Data1,Data2)
		VALUES
		(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@termenFinal,@CantNecesara
		,RTRIM(CONVERT(CHAR(20),@CantNecesara))
			+' din Contracte aprov furnizor'
		,0,0,0,0,'','')
	
	--if @Cod='5243G015004000'
	--	PRINT 'STOP'

	UPDATE_pozComLivr:
	UPDATE pozcon
	SET Termen=ISNULL((SELECT MAX(Termen) FROM Termene t WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
			and p.Contract=t.Contract and p.Cod=t.Cod), @termenFinal)
		,Cant_aprobata=@CantDescStoc
		,Mod_de_plata=CONVERT(CHAR(8),@dataCurenta,112)
		,UM=CASE WHEN @amDatTermene=0 OR @nZiScad=1 THEN CASE WHEN @CantNecesara>=0.001 THEN '1' ELSE '' END ELSE UM END
		,Zi_scadenta_din_luna=-1 
		/*,Explicatii=LEFT(REPLACE((SELECT RTRIM(t.Explicatii)+' la '+LTRIM(RTRIM(CONVERT(CHAR(20),t.Termen,103)))+' ' AS [data()] FROM Termene t 
			WHERE p.Subunitate=t.Subunitate AND p.Tip=t.Tip AND p.Data=t.Data and p.Tert=t.Tert 
		and p.Contract=t.Contract and p.Cod=t.Cod ORDER BY t.Termen FOR XML PATH('')),'  ',CHAR(10)+CHAR(13)),200)*/
	FROM pozcon p
	WHERE CURRENT OF pozComLivr
	
	NEXT_pozComLivr:
	FETCH NEXT FROM pozComLivr INTO @Cod, @CantComLivr, @termenComLivr, @CantAprobLivr, @termenAprobLivr, @CantRealizataBK
		,@cUM, @nZiScad, @amTermene, @StocDisponibil, @StocRezervat, @TermenMaxim, @transferuri, @avize, @alteiesiri
	
END
CLOSE pozComLivr
DEALLOCATE pozComLivr

DROP TABLE #cantAprobAltele
DROP TABLE #cantAprobAlte
DROP TABLE #stocRezervat
DROP TABLE #stocGestiune
DROP TABLE #codGestComLivr

--SELECT * FROM pozComLivrTMP
--select * from  #cantAprobAltele
--select * from  #cantAprobAlte
--select * from  #stocRezervat
--select * from  #stocGestiune
--select * from  #codGestComLivr
