
CREATE PROCEDURE wIaPlanificareGantt @sesiune VARCHAR(50), @parXML XML
AS


	IF EXISTS (select 1 from sys.objects where name='wIaPlanificareGanttSP')
	begin
		exec wIaPlanificareGanttSP @sesiune=@sesiune, @parXML=@parXML
		return 0
	end

	DECLARE 
		@dataJos DATETIME, @dataSus DATETIME, @docXML XML, @interventii XML,
		@f_comanda varchar(100), @f_operatie varchar(100)
		
	select
		@dataJos = ISNULL(@parXML.value('(/*/@datajos)[1]', 'datetime'),'01/01/1901'),
		@dataSus = ISNULL(@parXML.value('(/*/@datasus)[1]', 'datetime'),'01/01/2100'),
		@f_comanda = ISNULL(@parXML.value('(/*/@f_comanda)[1]', 'varchar(100)'),'%'),
		@f_operatie = ISNULL(@parXML.value('(/*/@f_operatia)[1]', 'varchar(100)'),'%')


	IF OBJECT_ID('tempdb..#plan_gantt') IS NOT NULL
		DROP TABLE #plan_gantt


	create table #plan_gantt (id int, idOp int, comanda varchar(20), resursa varchar(20), dataStart datetime, datastop datetime, orastart varchar(4), orastop varchar(4), cantitate float, detalii xml)

	/* Inseram pozitiile de tip "centralizare", care au antet si detaliile lor se iau de acolo */
	insert into #plan_gantt(id , idOp , comanda , resursa, dataStart , datastop , orastart , orastop , cantitate , detalii )
	select
		p.id, p.idop, p.comanda, res.id, p.datastart, p.datastop, p.orastart,  p.orastop,
		p.cantitate, ap.detalii
	from AntetPlanificare ap
	JOIN planificare p on ap.idAntet=p.idAntet
	JOIN resurse res on res.id=ap.idResursa

	/* Restul pozitiilor, "normale" */
	insert into #plan_gantt(id , idOp , comanda , resursa, dataStart , datastop , orastart , orastop , cantitate , detalii )
	select
		p.id, p.idop, p.comanda, p.resursa, p.datastart, p.datastop, p.orastart, p.orastop, p.cantitate, p.detalii
	from planificare p 
	where idAntet is null


	SELECT 
		rtrim(s.descriere) + ' (' + rtrim(s.cod) + ')' AS '@utilaj', rtrim(s.cod) AS '@cod_masina', rtrim(s.descriere) AS '@tooltiputilaj', 
		(
			SELECT 
				rtrim(p.comanda) AS '@comanda', CONVERT(VARCHAR(10), p.dataStart, 101) AS '@dataStart', convert(INT, SUBSTRING(oraStart, 1, 2)) AS '@oraStart', 
				CONVERT(VARCHAR(10), p.dataStop, 101) AS '@dataStop', 
				convert(INT, SUBSTRING(oraStop, 1, 2)) AS '@oraStop', rtrim(isnull(cp.Denumire, '')) AS '@denoperatie', convert(INT, SUBSTRING(oraStart, 3, 2)) AS '@minutStart', 
				convert(INT, SUBSTRING(oraStop, 3, 2)) AS '@minutStop', 
				CONVERT(DECIMAL(15, 2), p.cantitate) AS '@cantitate', p.id AS '@id', rtrim(cp.Cod) AS '@operatie', rtrim(com.Tip_comanda) AS '@tip', RTRIM(com.Starea_comenzii) AS '@stare', 
				(CASE WHEN com.Starea_comenzii = 'S' THEN 'Simulare' + CHAR(13) WHEN com.Tip_comanda = 'X' THEN 'Interventie' + CHAR(13) ELSE '' END) AS '@tooltip', 
				(CASE com.Starea_comenzii WHEN 'L' THEN 'Lansata' WHEN 'S' THEN 'Simulata' END) AS '@starecomanda', 
				(CASE com.tip_comanda WHEN 'X' THEN 'Interventie' WHEN 'P' THEN 'Productie' END) AS '@tipcomanda', 'Alte informatii' AS '@info',
				p.resursa '@resursa', s.descriere '@denresursa'
			FROM #plan_gantt p
			INNER JOIN pozLansari pz ON pz.tip = 'O' AND pz.id = p.idOp
			INNER JOIN catop cp ON cp.Cod = pz.cod
			LEFT JOIN comenzi com ON com.Comanda = p.comanda AND com.Tip_comanda IN ('P', 'X') and com.Starea_comenzii in ('L','S')
			LEFT JOIN pozLansari ln ON ln.cod = com.Comanda AND ln.tip = 'L'
			WHERE 
				p.resursa = s.id  AND 
				(p.dataStart BETWEEN @dataJos AND @dataSus OR p.dataStop BETWEEN @dataJos AND @dataSus)		and 
				(cp.denumire like @f_operatie or cp.cod like @f_operatie) and
				(com.comanda like @f_comanda )		
			FOR XML path('Operatie'), root('Planificari'), type
		)
	FROM Resurse s
	FOR XML path('Resursa'), root('Date')
