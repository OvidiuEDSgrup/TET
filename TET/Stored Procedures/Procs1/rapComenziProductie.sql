
CREATE PROCEDURE rapComenziProductie @dataJos DATETIME = '1901-01-01', @dataSus DATETIME = '2100-01-01', @cod VARCHAR(20) = NULL, @stare varchar(20) =  'T' /* toate */, @comanda varchar(20)=null
AS

	IF OBJECT_ID('tempdb.dbo.#stariComenzi') IS NOT NULL
		drop table #stariComenzi

	create table #stariComenzi (stare varchar(10), denumire varchar(500))
	insert into #stariComenzi  (stare, denumire)
	select 'S', 'Simulare' UNION
	select 'P', 'Pregatire' UNION
	select 'L', 'Lansata' UNION
	select 'A', 'Alocata' UNION
	select 'I', 'Inchisa'  UNION
	select 'N', 'Anulata'  UNION
	select 'B', 'Blocata' 

	SELECT 
		RTRIM(pl.cod) AS comanda, RTRIM(n.cod) AS codprodus, RTRIM(n.denumire) AS denprodus, CONVERT(VARCHAR(10), c.Data_lansarii, 103) AS datalans, CONVERT(DECIMAL(15, 3), pl.cantitate) AS cantlansat, 
		CONVERT(DECIMAL(15, 3), ISNULL(cl.cant,0)) AS cantraportat, ISNULL(sc.denumire,'Alta') AS starecom,
		CONVERT(VARCHAR(10), c.data_inchiderii, 103) datainchiderii
	FROM pozLansari pl
	INNER JOIN comenzi c ON c.comanda = pl.cod AND pl.tip = 'L'
	INNER JOIN pozTehnologii pt ON pt.idp IS NULL AND pt.tip = 'T' AND pt.id = pl.idp
	LEFT JOIN #stariComenzi sc on sc.stare=c.starea_comenzii
	INNER JOIN nomencl n ON n.cod = pt.cod
	OUTER APPLY (select sum(cantitate) cant from PozDoc where subunitate='1' and tip='PP' and comanda=pl.cod and n.cod=cod) cl
	WHERE 
		((c.Data_lansarii BETWEEN @dataJos AND @dataSus AND @comanda is null )  OR (c.comanda=@comanda)) and
		(@cod IS NULL OR n.cod = @cod) AND
		(@stare ='T' OR c.starea_comenzii = @stare) 		
	ORDER BY c.data_lansarii
