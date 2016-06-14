IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wOPGenerareTransferFundamenteComanda_p')
	DROP PROCEDURE wOPGenerareTransferFundamenteComanda_p
GO

CREATE PROCEDURE wOPGenerareTransferFundamenteComanda_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE
		@idPozContract INT, @idContract INT, @idPozContractCorespondent INT, @idContractCorespondent INT, 
		@mesaj VARCHAR(500), @utilizator VARCHAR(100), @gestiune VARCHAR(50), @numar VARCHAR(20), 
		@tipGestiune VARCHAR(1), @tipGestiuneRez VARCHAR(1),@subunitate VARCHAR(9), @gestiune_primitoare varchar(20)
		, @gestiuneRezervari VARCHAR(20), @cuRezervari INT, @codArticol varchar(20), @cantitate float

	SET @idPozContract = @parXML.value('(/*/@idPozContract)[1]', 'int')
	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @idPozContractCorespondent = @parXML.value('(/*/@idPozContractCorespondent)[1]', 'int')
	SET @idContractCorespondent = @parXML.value('(/*/@idContractCorespondent)[1]', 'int')
	SET @codArticol = @parXML.value('(/*/@cod)[1]', 'varchar(20)')
	SET @gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)')
	SET @gestiune_primitoare = @parXML.value('(/*/@gestiune_primitoare)[1]', 'varchar(20)')
	SET @cantitate = @parXML.value('(/*/@cantitate)[1]','float')

	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @Utilizator OUTPUT

	/** Validari **/
	--IF @idContract IS NULL
	--	RAISERROR ('Alegeti cel putin si cel mult o singura linie din tabel!', 11, 1)

	/** Tip gestiune **/
	SELECT 
		@tipGestiune = tip_gestiune
	FROM gestiuni
	WHERE cod_gestiune = @gestiune

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT;

	IF object_id('tempdb..#pozitiitransfer_p') IS NOT NULL
		DROP TABLE #pozitiitransfer_p;

			
	WITH Antet AS (
		SELECT @idContract AS idContract, 
			@idPozContract AS idPozContract, 
			@idContractCorespondent AS idContractCorespondent, 
			@idPozContractCorespondent AS idPozContractCorespondent,
			@gestiune AS gestiune, @gestiune_primitoare AS gestiune_primitoare,
			@codArticol AS cod, @cantitate AS cantitate),
		Pozitii AS (
		SELECT COALESCE(nullif(r.col.value('(@idContract)[1]','int'),0), nullif(p.col.value('(@idContract)[1]','int'),0), A.idContract) AS idComAprov, 
			COALESCE(nullif(r.col.value('(@idPozContract)[1]','int'),0), nullif(p.col.value('(@idPozContract)[1]','int'),0), A.idPozContract) AS idPozComAprov, 
			COALESCE(nullif(r.col.value('(@idContractCorespondent)[1]','int'),0), nullif(p.col.value('(@idContractCorespondent)[1]','int'),0), A.idContractCorespondent) AS idContract, 
			COALESCE(nullif(r.col.value('(@idPozContractCorespondent)[1]','int'),0), nullif(p.col.value('(@idPozContractCorespondent)[1]','int'),0), A.idPozContractCorespondent) AS idPozContract, 
			COALESCE(nullif(r.col.value('(@cod)[1]','varchar(20)'),''), nullif(p.col.value('(@cod)[1]','varchar(20)'),''), A.cod) AS cod, 
			COALESCE(nullif(r.col.value('(@gestiune)[1]','varchar(50)'),''), nullif(p.col.value('(@gestiune)[1]','varchar(50)'),''), A.gestiune) AS gestiune, 
			COALESCE(nullif(r.col.value('(@gestiune_primitoare)[1]','varchar(50)'),''), nullif(p.col.value('(@gestiune_primitoare)[1]','varchar(50)'),''), A.gestiune_primitoare) AS gestiune_primitoare, 
			COALESCE(nullif(r.col.value('(@cantitate)[1]','float'),0), nullif(p.col.value('(@cantitate)[1]','float'),0), A.cantitate) AS cantitate, 
			convert(decimal(15, 3), 0) AS stoc, convert(decimal(15, 3), 0) AS rezervat, convert(decimal(15, 3), 0) AS transferat, 
			convert(decimal(15, 3), 0) AS in_curs, convert(decimal(15, 3), 0) AS detransferat
		FROM Antet A 
			OUTER APPLY @parXML.nodes('/*/row') p(col)
			OUTER APPLY p.col.nodes('./row') r(col)),
		Pozitii_unice AS (
		SELECT *,
			ROW_NUMBER() OVER(PARTITION BY P.idPozContract ORDER BY P.gestiune_primitoare DESC) AS nrPozContr
		FROM Pozitii P)
		SELECT * 
		INTO #pozitiitransfer_p
		FROM Pozitii_unice P
		WHERE P.nrPozContr=1
		
	UPDATE pc
		SET rezervat = isnull(pd.rezervat, 0),
			transferat = isnull(pd.transferat, 0),
			stoc = isnull(stoc.stoc,0), 
			in_curs = isnull(ic.in_curs,0)
	FROM #pozitiitransfer_p pc
	LEFT JOIN 
	(
		SELECT 
			lc.idPozContract idPozContract, 
			SUM(case when pd.tip in ('AP', 'AS', 'AC') then pd.cantitate else 0 end) transferat,
			SUM(case when pd.tip='TE' AND pd.Gestiune_primitoare = @gestiuneRezervari then pd.cantitate else 0 end) rezervat
		FROM LegaturiContracte lc
		inner join #pozitiitransfer_p pc on lc.idpozcontract=pc.idpozcontract
		LEFT JOIN PozDoc pd ON pd.idPozDoc = lc.idPozDoc AND pd.Tip in ('AP', 'AS', 'AC', 'TE')
		GROUP BY lc.idPozContract
	) pd ON pd.idPozContract = pc.idPozContract
	left join 
	(
		select pc.idPozContract idPozContract, SUM(st.stoc) stoc
		from #pozitiitransfer_p pc
		inner join stocuri st on st.subunitate=@subunitate and st.cod_gestiune=pc.gestiune and pc.cod=st.cod
		group by pc.idpozcontract
	) stoc on pc.idPozContract=stoc.idpozcontract
	left join 
	(
		select pc.idPozContract, SUM(pca.cantitate) in_curs
		from #pozitiitransfer_p pc
		inner join LegaturiContracte lc on lc.idPozContractCorespondent=pc.idPozContract
		inner join PozContracte pca on pca.idPozContract=lc.idPozContract 
		inner join Contracte ca on ca.idContract=pca.idContract
		CROSS APPLY 
		(
			select top 1 j.stare stare, s.inchisa from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=ca.tip and j.idContract=ca.idContract order by j.data desc
		) st 
		where ISNULL(st.inchisa,0)=0 
		group by pc.idpozcontract
	) ic on pc.idPozContract=ic.idpozcontract

	UPDATE #pozitiitransfer_p
		SET detransferat = cantitate - transferat
	
	SELECT gestiune, gestiune_primitoare
	FROM #pozitiitransfer_p P
	GROUP BY gestiune, gestiune_primitoare
	ORDER BY SUM(P.cantitate) DESC
	FOR XML RAW, ROOT('Date')
	
	/** Datele din grid **/
	SELECT (
		SELECT c.idContract, idPozContract
			, c.tert
			, pr.gestiune
			, rtrim(pr.cod) AS cod, rtrim(n.denumire) AS denumire
			, convert(DECIMAL(15, 3), pr.cantitate) AS cantitate
			, convert(DECIMAL(15, 3), pr.in_curs) in_curs
			, convert(DECIMAL(15, 3), pr.rezervat) rezervat
			, convert(DECIMAL(15, 3), pr.stoc) stoc
			, convert(DECIMAL(15, 3), pr.detransferat) detransferat
		FROM #pozitiitransfer_p pr
			INNER JOIN nomencl n ON n.cod = pr.cod
			INNER JOIN Contracte c on c.idContract=pr.idContract
		FOR XML raw, type
		)
	FOR XML path('DateGrid'), root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareTransferFundamenteComanda_p)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
