
CREATE PROCEDURE yso_wIaDocumenteStorno @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@mesaj VARCHAR(500), @idContract INT, @f_cod VARCHAR(40), @f_denumire VARCHAR(60), @f_numardoc VARCHAR(50), 
		@gestiuneRezervari varchar(20), @cuRez int, @ContAvizNefacturat varchar(20)
		,@tip varchar(2), @numar varchar(20), @data datetime

	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRez OUTPUT, 0, @gestiuneRezervari OUTPUT
	EXEC luare_date_par 'GE', 'CTCLAVRT ', 0, 0, @ContAvizNefacturat output
select "@parXML"=@parXML
	SELECT
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@tip = ISNULL(@parXML.value('(/*/@tipdocument)[1]', 'varchar(2)'), @parXML.value('(/*/@tip)[1]', 'varchar(2)')),
		@numar= ISNULL(@parXML.value('(/*/@nrdocument)[1]', 'varchar(20)'), @parXML.value('(/*/@numar)[1]', 'varchar(20)')),
		@data= @parXML.value('(/*/@data)[1]', 'datetime'),
		@f_cod = '%' + @parXML.value('(/*/@f_cod)[1]', 'varchar(40)') + '%',
		@f_denumire = '%' + @parXML.value('(/*/@f_denumire)[1]', 'varchar(60)') + '%',
		@f_numardoc = '%' + @parXML.value('(/*/@f_numardoc)[1]', 'varchar(50)') + '%'

	/**
		Pentru a putea arata documentele care "tin de contract" chiar daca nu sunt direct legate prin tabel de acesta 
			1. un contract furn.->com. livrare->factura: se vor putea vedea facturile si pe contract...
			2. facturile de avans se leaga de contract prin idPozDoc, idJurnal (fara idPozContract) in legaturi
					
	**/

	IF OBJECT_ID('tempdb..#idpozs') IS NOT NULL
		drop table #idpozs

	select
		p.idPozDoc idPozDocSursa, ls.idStorno idPozDoc
	into #idpozs
	from pozdoc p 
		JOIN LegaturiStornare ls on ls.idSursa=p.idPozDoc
	where p.Subunitate='1' and p.Tip=@tip and p.Data=@data and p.Numar=@numar

	IF OBJECT_ID('tempdb..#pozDocStorno') IS NOT NULL
		drop table #pozDocStorno

	SELECT rtrim(pc.Tip) as tip, pc.data as data, rtrim(pc.Numar) as numar,
		RTRIM(pd.Tip) as tipS, pd.data AS dataS, RTRIM(pd.numar) AS numarS
		, RTRIM(pd.cod) AS cod, RTRIM(n.Denumire) AS denumire, RTRIM(pd.Cod_intrare) AS codintrare, convert(DECIMAL(15, 2), pd.cantitate) AS cantitate, 
		convert(DECIMAL(15, 2), case when pd.tip='TE' and pd.Gestiune_primitoare=@gestiuneRezervari and @cuRez=1 and pd.colet is not null then pd.cantitate else 0 end) AS pregatit,
		(case 
			when (pd.tip='TE' and pd.Gestiune_primitoare=@gestiuneRezervari and @cuRez=1) then 'Rezervare' 
			when (pd.tip='TE' ) then 'Transfer' 
			when (pd.tip='RM' ) then 'Receptie' 
			when pd.tip in ('AP','AS') and lc.idPozDocSursa is not null then (case when pd.Cont_factura=@ContAvizNefacturat then 'Aviz' else 'Factura' end) 
			when lc.idPozDocSursa IS NULL and pd.tip in ('AS','AP') then 'Factura avans'
			when pd.tip='AC' then 'Bon' else pd.tip end) as denTipS,		
		pd.idPozDoc as idPozDocStorno, pc.idPozDoc as idPozDocSursa, 
		convert(decimal(17,2),(case when pd.tip in('CM') then pd.pret_de_stoc else pd.pret_valuta end)) as pret, 
		convert(decimal(17,2),pd.cantitate * (case when pd.tip in('CM') then pd.pret_de_stoc else pd.pret_valuta end)) as valoare, 
		(case when pd.tip='TE' and pd.Gestiune_primitoare=@gestiuneRezervari and @cuRez=1 and pd.colet is not null then '#FF0000' else '#000000' end) as culoare,
		pd.detalii
		,nrCurentLinie=ROW_NUMBER() over(partition by pd.subunitate, pd.tip, pd.data, pd.numar order by pd.numar_pozitie)
		,nrTotalLinii=COUNT(1) over(partition by pd.subunitate, pd.tip, pd.data, pd.numar)
		,rkDoc=DENSE_RANK() over(partition by pc.subunitate, pc.tip, pc.data, pc.numar order by pd.subunitate, pd.tip, pd.data, pd.numar)
	into #pozDocStorno
	FROM #idpozs lc
	LEFT JOIN pozdoc pc  ON lc.idPozDocSursa=pc.idPozDoc
	--INNER JOIN Contracte co ON co.idContract = pc.idContract
	INNER JOIN PozDoc pd ON pd.idPozDoc = lc.idPozDoc
	LEFT JOIN nomencl n	ON n.Cod = pd.cod
	WHERE (@f_numardoc IS NULL OR pd.Numar LIKE @f_numardoc)
		AND (@f_denumire IS NULL OR n.Denumire LIKE @f_denumire)
		AND (@f_cod IS NULL OR pd.cod LIKE @f_cod)

	declare @pozXML xml
	set @pozXML=(
		select tip,convert(varchar(10),data,101) as data,numar
			, tipS, convert(varchar(10),dataS,101) as dataS, numarS, denTipS
			, cod=(case dc.nrTotalLinii when 1 then cod end), denumire=(case dc.nrTotalLinii when 1 then denumire end)
			, codintrare=(case dc.nrTotalLinii when 1 then codintrare end), cantitate=(case dc.nrTotalLinii when 1 then cantitate end)
			, pret=(case dc.nrTotalLinii when 1 then pret end), valoare=(case dc.nrTotalLinii when 1 then valoare end)
			, idPozDocSursa=(case dc.nrTotalLinii when 1 then idPozDocSursa end), idPozDocStorno=(case dc.nrTotalLinii when 1 then idPozDocStorno end)
			, culoare
			,(select tip,convert(varchar(10),data,101) as data,numar
				--,pd.tipDocStorno, convert(varchar(10),pd.dataDocStorno,101) as dataDocStorno, pd.nrDocStorno
				,pd.cod, pd.denumire, pd.codintrare, pd.cantitate, pd.pret, pd.valoare, pd.culoare, pd.idPozDocSursa, pd.idPozDocStorno
			from #pozDocStorno pd
			where pd.tipS=dc.tipS and pd.dataS=dc.dataS and pd.numarS=dc.numarS
				and pd.nrTotalLinii>1
			order by pd.idPozDocStorno
			for xml raw, type)
		from #pozDocStorno dc
		where dc.nrCurentLinie=1
		order by dc.dataS, dc.tipS, dc.numarS
		for xml raw, root('Ierarhie')
		)
	
	IF @pozXML IS NOT NULL and (select MAX(rkDoc) from #pozDocStorno)=1
		SET @pozXML.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

	SELECT @pozXML
	FOR XML path('Date')

	select 1 as areDetaliiXml for xml raw,root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (yso_wIaDocumenteStorno)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
