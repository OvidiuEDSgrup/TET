
CREATE PROCEDURE wIaDocumenteComanda @sesiune VARCHAR(50), @parXML XML
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

	SELECT 
		RTRIM(pd.numar) AS numardoc, CONVERT(VARCHAR(10), pd.data, 101) AS data, RTRIM(pd.cod) AS cod, RTRIM(n.Denumire) AS 
		denumire, RTRIM(pd.Cod_intrare) AS codintrare, convert(DECIMAL(15, 2), pd.cantitate) AS cantitate,
		(case 
			when (pd.tip='TE' and pd.Gestiune_primitoare=@gestiuneRezervari and @cuRez=1) then 'Rezervare' 
			when (pd.tip='TE' ) then 'Transfer' 
			when pd.tip in ('AP','AS') and lc.idPozContract is not null then (case when pd.Cont_factura=@ContAvizNefacturat then 'Aviz' else 'Factura' end) 
			when lc.idPozContract IS NULL and pd.tip in ('AS','AP') then 'Factura avans'
			when pd.tip='AC' then 'Bon' else pd.tip end) as tipdocument,		
		pd.idPozDoc as idPozDoc, pc.idPozContract as idPozContract, pc.idContract as idContract,
		convert(decimal(17,2),pd.cantitate * (case when pd.tip in('CM') then pd.pret_de_stoc else pd.pret_valuta end)) as valoare,
		pd.detalii
	FROM #idpozc lc
	LEFT JOIN PozContracte pc  ON lc.idPozContract=pc.idPozContract
	INNER JOIN PozDoc pd ON pd.idPozDoc = lc.idPozDoc
	LEFT JOIN nomencl n	ON n.Cod = pd.cod
	WHERE (@f_numardoc IS NULL OR pd.Numar LIKE @f_numardoc)
		AND (@f_denumire IS NULL OR n.Denumire LIKE @f_denumire)
		AND (@f_cod IS NULL OR pc.cod LIKE @f_cod)
	FOR XML raw, root('Date')

	select 1 as areDetaliiXml for xml raw,root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wIaDocumenteComanda)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
