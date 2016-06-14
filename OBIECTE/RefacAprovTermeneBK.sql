	
DECLARE @Subunitate CHAR(9), @Tip CHAR(2), @Contract CHAR(20), @Data DATETIME, @Tert CHAR(13), @Cod CHAR(30), @CantRamasa FLOAT
	,@amDatTermene smallint, @reconfirmTermene smallint
DECLARE	@CantComPozAprov FLOAT, @CantDescAprov FLOAT, @TermenAprov DATETIME
	,@ordPozaprov int, @ordRealizat int, @ordComandat float, @ordTermen int

SELECT TOP 1 
@Subunitate='1'
,@Tip='BK'
,@Contract=Contract
,@Tert=Tert
,@Data=data
,@Cod=Cod
,@CantRamasa=pozcon.Cantitate-pozcon.Cant_aprobata-(pozcon.Cant_realizata+pozcon.Cant_rezervata)
,@reconfirmTermene=pozcon.Zi_scadenta_din_luna
,@amDatTermene=ISNULL((select top 1 1 from termene t where pozcon.Subunitate=t.Subunitate AND pozcon.Tip=t.Tip 
	AND pozcon.Data=t.Data and pozcon.Tert=t.Tert and pozcon.Contract=t.Contract and pozcon.Cod=t.Cod),0)
FROM yso.pozconexp pozcon where tip='bk' and Contract='1031947' and cod='0014181'


--daca nu am stoc si nici nu este legata de o com de aprov atunci incerc sa leg pozitiile de o comanda de aprov existenta 
--si nelegata deja de alte comenzi de livrare
DECLARE @CantLibera FLOAT, @CantRealizata FLOAT, @contrAprov CHAR(20), @FurnAprov CHAR(13), @dataAprov DATETIME


DECLARE coduriAprovLibere CURSOR FOR
SELECT 1 as ordPozaprov
,ISNULL((SELECT 1 FROM pozcon p WHERE p.subunitate=pozcon.subunitate and p.tip=pozcon.tip and p.contract=pozcon.contract
	and p.data=pozcon.data and p.tert=pozcon.tert and ABS(p.cant_realizata)>=0.001),2) as ordRealizat
,-1*dbo.valoare_maxima(SUM(pozaprov.cant_comandata),0,null) as ordComandat
,DATEDIFF(day,getdate(),MAX(pozcon.termen)) as ordTermen
,pozcon.contract, pozcon.data, pozcon.Tert, MAX(pozcon.Termen) as Termen
,MAX(pozcon.Cant_aprobata)-ISNULL((SELECT SUM(Cant_comandata) FROM pozaprov pa WHERE pa.Contract=pozcon.Contract 
	AND pa.Data=pozcon.Data AND pa.Furnizor=pozcon.Tert and pa.cod=pozcon.cod AND pa.tip='BK' 
	AND pa.Comanda_livrare<>'' AND (pa.Comanda_livrare<>@contract OR pa.Beneficiar<>@Tert OR pa.Data_comenzii<>@Data)
	AND ABS(pa.Cant_comandata)>=0.001),0) AS Cant_libera
, MAX(pozcon.Cant_realizata) as Cant_realizata
FROM pozaprov 
	INNER JOIN pozcon ON pozaprov.Contract=pozcon.Contract AND pozaprov.Data=pozcon.Data AND pozaprov.Furnizor=pozcon.Tert 
		and pozaprov.cod=pozcon.cod AND pozaprov.tip='BK' AND pozaprov.Comanda_livrare=@contract AND pozaprov.Beneficiar=@Tert AND pozaprov.Data_comenzii=@Data
	INNER JOIN con ON con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and con.data=pozcon.data 
		and con.tert=pozcon.tert and con.contract=pozcon.contract
WHERE pozcon.subunitate=@subunitate AND pozcon.tip='FC' AND pozcon.cod=@Cod
GROUP BY pozcon.subunitate, pozcon.Tip, pozcon.contract, pozcon.data, pozcon.Tert, pozcon.cod
UNION ALL
SELECT 2 as ordPozaprov
,2 as ordRealizat
,1 as ordComandat
,DATEDIFF(day,getdate(),pozcon.termen) as ordTermen
,pozcon.contract, pozcon.data, pozcon.Tert, pozcon.Termen, pozcon.Cant_aprobata
-ISNULL((SELECT SUM(Cant_comandata) FROM pozaprov WHERE pozaprov.Contract=pozcon.Contract 
	AND pozaprov.Data=pozcon.Data AND pozaprov.Furnizor=pozcon.Tert and pozaprov.cod=pozcon.cod AND pozaprov.tip='BK' 
	AND pozaprov.Comanda_livrare<>'' AND pozaprov.Cant_comandata>=0.001),0) AS Cant_libera
, pozcon.Cant_realizata
FROM pozcon INNER JOIN con ON con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and con.data=pozcon.data 
	and con.tert=pozcon.tert and con.contract=pozcon.contract
WHERE pozcon.cod=@Cod AND pozcon.subunitate=@subunitate AND pozcon.tip='FC'
	AND NOT EXISTS (SELECT 1 FROM pozcon p WHERE p.subunitate=pozcon.subunitate and p.tip=pozcon.tip and p.contract=pozcon.contract
		and p.data=pozcon.data and p.tert=pozcon.tert and ABS(pozcon.cant_realizata)>=0.001)
	AND NOT EXISTS (SELECT 1 FROM pozaprov WHERE pozaprov.Contract=pozcon.Contract 
		AND pozaprov.Data=pozcon.Data AND pozaprov.Furnizor=pozcon.Tert and pozaprov.cod=pozcon.cod 
		AND pozaprov.tip='BK' AND pozaprov.Comanda_livrare=@contract AND pozaprov.Beneficiar=@Tert AND pozaprov.Data_comenzii=@Data)
ORDER BY 1,2,3,4

OPEN coduriAprovLibere
FETCH NEXT FROM coduriAprovLibere INTO @ordPozaprov, @ordRealizat, @ordComandat, @ordTermen
	,@contrAprov, @dataAprov, @FurnAprov, @TermenAprov, @CantLibera, @CantRealizata
		
WHILE @@FETCH_STATUS<>-1 
BEGIN
	--IF @CantLibera<0.001 GOTO NEXT_coduriAprovLibere AND @CantRamasa>=0.001 
	
	SET @CantDescAprov=CASE WHEN @CantLibera<@CantRamasa THEN @CantLibera ELSE @CantRamasa END
	SET @CantDescAprov=dbo.valoare_maxima(@CantDescAprov,0,null)
	
	IF @ordPozaprov=1	
		UPDATE pozaprov
		SET Cant_comandata=CASE @CantRealizata WHEN 0 THEN @CantDescAprov ELSE Cant_comandata END
		WHERE Contract=@contrAprov and Data=@dataAprov AND Furnizor=@FurnAprov AND Cod=@Cod AND Tip=@Tip
			AND Comanda_livrare=@Contract AND Data_comenzii=@Data AND Beneficiar=@Tert
		
	IF @ordPozaprov=2 AND @CantDescAprov>=0.001	--AND (@amDatTermene=0 or @reconfirmTermene=1) 
		INSERT INTO pozaprov --Contract, Data, Furnizor, Cod, Tip, Comanda_livrare, Data_comenzii, Beneficiar
		(Contract,Data,Furnizor,Cod,Comanda_livrare,Data_comenzii,Beneficiar
		,Cant_comandata,Cant_receptionata,Cant_realizata,Tip)
		 VALUES
		(@contrAprov,@dataAprov,@FurnAprov,@Cod,@Contract,@Data,@Tert,@CantDescAprov,0,0,@Tip)
		
	NEXT_coduriAprovLibere:	   
	SET @CantRamasa=@CantRamasa-@CantDescAprov --aici nu cred ca e corect ca se face scad desi e posibil sa nu se fi facut desc
	FETCH NEXT FROM coduriAprovLibere INTO @ordPozaprov, @ordRealizat, @ordComandat, @ordTermen
		,@contrAprov, @dataAprov, @FurnAprov, @TermenAprov, @CantLibera, @CantRealizata
END
CLOSE coduriAprovLibere
DEALLOCATE coduriAprovLibere

-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
--daca am pozitii legate de o comanda de aprovizionare aduc termenul cel mai tarziu de acolo, altfel las termenul neatins

DECLARE cursorTermenePozAprov CURSOR FOR
SELECT Termen, SUM(pozaprov.Cant_comandata) AS Cant_comandata
FROM pozaprov INNER JOIN pozcon ca ON ca.Subunitate=@Subunitate AND ca.Tip='FC' 
	AND ca.Data=pozaprov.Data AND ca.Tert=pozaprov.Furnizor AND ca.Contract=pozaprov.Contract and ca.Cod=pozaprov.Cod
WHERE pozaprov.Beneficiar=@Tert AND pozaprov.Data_comenzii=@Data AND pozaprov.Comanda_livrare=@Contract AND pozaprov.Cod=@Cod
	and pozaprov.cant_comandata>=0.001
GROUP BY ca.Termen

OPEN cursorTermenePozAprov
FETCH NEXT FROM cursorTermenePozAprov INTO @TermenAprov, @CantComPozAprov

WHILE @@FETCH_STATUS<>-1 
BEGIN
	--SET @CantDescAprov=CASE WHEN @CantComPozAprov<@CantRamasa THEN @CantComPozAprov ELSE @CantRamasa END
	UPDATE Termene
	SET Cantitate=t.Cantitate+@CantComPozAprov
		,Explicatii=LEFT(RTRIM(ISNULL(NULLIF(t.Explicatii,'')+'(+)',''))
			+RTRIM(CONVERT(CHAR(20),@CantComPozAprov))
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
		(@Subunitate,@Tip,@Contract,@Tert,@Cod,@Data,@TermenAprov,@CantComPozAprov
		,RTRIM(CONVERT(CHAR(20),@CantComPozAprov))
			+' din Aprovizionare '
		,0,0,0,0,'','')
	
	--SET @CantRamasa=@CantRamasa-@CantDescAprov

	FETCH NEXT FROM cursorTermenePozAprov INTO @TermenAprov, @CantComPozAprov
END
CLOSE cursorTermenePozAprov
DEALLOCATE cursorTermenePozAprov


select * from termene t where t.Subunitate=@Subunitate and t.Tip=@Tip and t.Contract=@Contract and t.Data=@data and t.Cod=@Cod