
CREATE PROCEDURE yso_wIaFundamenteComanda @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@mesaj VARCHAR(500), @idContract INT, @f_cod VARCHAR(40), @f_denumire VARCHAR(60), @f_numardoc VARCHAR(50), 
		@gestiuneRezervari varchar(20), @cuRez int, @ContAvizNefacturat varchar(20)

	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRez OUTPUT, 0, @gestiuneRezervari OUTPUT
	EXEC luare_date_par 'GE', 'CTCLAVRT ', 0, 0, @ContAvizNefacturat output

	SELECT
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@f_cod = '%' + @parXML.value('(/*/@f_cod)[1]', 'varchar(40)') + '%',
		@f_denumire = '%' + @parXML.value('(/*/@f_denumire)[1]', 'varchar(60)') + '%',
		@f_numardoc = '%' + @parXML.value('(/*/@f_numardoc)[1]', 'varchar(50)') + '%'


	/**
		Pentru a putea arata documentele care "tin de contract" chiar daca nu sunt direct legate prin tabel de acesta 
			1. un contract furn.->com. livrare->factura: se vor putea vedea facturile si pe contract...
			2. facturile de avans se leaga de contract prin idPozDoc, idJurnal (fara idPozContract) in legaturi				
	**/

	IF OBJECT_ID('tempdb..#idpozc') IS NOT NULL
		drop table #idpozc

	select distinct pc.idPozCon idPozContract, pn.idPozContract idPozContractCorespondent
	into #idpozc
	from PozContracte pn join Contracte cn on cn.idContract=pn.idContract 
		join necesaraprov na on na.Numar=cn.numar and na.Data=cn.data and na.Numar_pozitie=pn.idPozContract
		join pozaprov pa on pa.Tip='N' and pa.Comanda_livrare=na.Numar and pa.Data_comenzii=na.Data and pa.Beneficiar='' and pa.Cod=na.Cod
		join pozcon pc on pc.Subunitate='1' and pc.tip='FC' and pc.Contract=pa.Contract and pc.Data=pa.Data and pc.Tert=pa.Furnizor and pc.Cod=pa.Cod 
		join con c on c.Subunitate=pc.Subunitate and c.Tip=pc.tip and c.Contract=pc.Contract and c.data=pc.data and pc.Tert=c.Tert 
	where cn.tip='RN' and c.idCon=@idContract 

/*
	select
		distinct p.idPozContract idPozContract, lc.idPozDoc idPozDoc
	into #idpozc
	from PozContracte p 
	JOIN LegaturiContracte lc on lc.idPozContract=p.idPozContract
	where p.idContract=@idContract
	UNION ALL
	select
		distinct lc2.idPozContract, lc2.idPozDoc
	from PozContracte pc
	JOIN LegaturiContracte lc on pc.idPozContract=lc.idPozContractCorespondent
	JOIN LegaturiContracte lc2 on lc2.idPozContract=lc.idPozContract
	where pc.idContract=@idContract and lc.idPozContractCorespondent is not null and lc2.idPozDoc IS not null
	UNION
	select
		NULL, lc.idPozDoc
	from JurnalContracte jc
	JOIN LegaturiContracte lc on jc.idJurnal=lc.idJurnal and lc.idPozContract is null and lc.idPozContractCorespondent is null and jc.idContract=@idContract
*/
	IF OBJECT_ID('tempdb..#pozContrFundamente') IS NOT NULL
		drop table #pozContrFundamente
	
	SELECT 
		cn.numar, cn.data,
		pn.cod, n.Denumire, pn.explicatii,
		pn.cantitate,
		cn.tip,
		RTRIM(ISNULL(NULLIF(cn.gestiune_primitoare, ''), cn.gestiune)) as gestiune_primitoare, ct.gestiune,
		pn.idPozContract as idPozContractCorespondent, pc.idPozContract,
		cn.idContract as idContractCorespondent, pc.idContract,
		pn.cantitate * pc.pret as valoare,
		pn.detalii,
		nrCurentLinie=ROW_NUMBER() over(partition by cn.tip, cn.data, cn.numar order by pn.idPozContract),
		nrTotalLinii=COUNT(1) over(partition by cn.tip, cn.data, cn.numar),
		rkDoc=DENSE_RANK() over(partition by ct.tip, ct.data, ct.numar 
			order by RTRIM(ISNULL(NULLIF(cn.gestiune_primitoare, ''), cn.gestiune)), cn.tip, cn.data, cn.numar)
	INTO #pozContrFundamente
	FROM #idpozc lc
		LEFT JOIN PozContracte pc  ON lc.idPozContract=pc.idPozContract LEFT JOIN Contracte ct on ct.idContract=pc.idContract
		INNER JOIN PozContracte pn ON pn.idPozContract = lc.idPozContractCorespondent INNER JOIN Contracte cn on cn.idContract=pn.idContract
		LEFT JOIN nomencl n	ON n.Cod = pn.cod
	WHERE (@f_numardoc IS NULL OR cn.Numar LIKE @f_numardoc)
		AND (@f_denumire IS NULL OR n.Denumire LIKE @f_denumire)
		AND (@f_cod IS NULL OR pn.cod LIKE @f_cod)

	declare @pozXML xml
	set @pozXML=(
		SELECT RTRIM(df.tip) AS tipDocFund, RTRIM(df.tip)+' - '+(case when (df.tip='RN') then 'Necesar Aprovizionare' else df.tip end) as denTipDocFund,	
			CONVERT(VARCHAR(10), df.data, 101) AS dataDocFund, RTRIM(df.numar) AS nrDocFund
			, RTRIM(df.gestiune_primitoare) as gestiune_primitoare, RTRIM(df.gestiune) as gestiune
			, RTRIM(CASE df.nrTotalLinii WHEN 1 THEN df.cod END) AS cod, RTRIM(CASE df.nrTotalLinii WHEN 1 THEN df.Denumire END) AS denumire
			, RTRIM(CASE df.nrTotalLinii WHEN 1 THEN df.explicatii END) AS explicatii
			, convert(DECIMAL(15, 2), (CASE df.nrTotalLinii WHEN 1 THEN df.cantitate END)) AS cantitate					
			, df.idContractCorespondent, (CASE df.nrTotalLinii WHEN 1 THEN df.idPozContractCorespondent END) AS idPozContractCorespondent
			, df.idContract, (CASE df.nrTotalLinii WHEN 1 THEN df.idPozContract END) AS idPozContract,
			convert(decimal(17,2),df.valoare) as valoare,
			df.detalii,
				(SELECT RTRIM(pf.cod) AS cod, RTRIM(pf.Denumire) AS denumire
					, RTRIM(df.gestiune) as gestiune, RTRIM(df.gestiune_primitoare) as gestiune_primitoare
					, convert(DECIMAL(15, 2), pf.cantitate) AS cantitate, RTRIM(pf.explicatii) AS explicatii
					, pf.idContractCorespondent, pf.idPozContractCorespondent, pf.idContract, pf.idPozContract
				FROM #pozContrFundamente pf
				WHERE pf.idContractCorespondent = df.idContractCorespondent and pf.nrTotalLinii > 1
				FOR XML RAW, TYPE)
		FROM #pozContrFundamente df
		WHERE df.nrCurentLinie = 1
		ORDER BY df.gestiune_primitoare, df.tip, df.data, df.numar
		FOR XML RAW, ROOT('Ierarhie'))
		
	IF @pozXML IS NOT NULL AND (SELECT MAX(rkDoc) FROM #pozContrFundamente)=1
		SET @pozXML.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')
	
	SELECT @pozXML FOR XML PATH('Date')
	
	select 1 as areDetaliiXml for xml raw,root('Mesaje')
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wIaFundamenteComanda)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
