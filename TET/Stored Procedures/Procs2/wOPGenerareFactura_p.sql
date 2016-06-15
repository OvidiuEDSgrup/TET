
CREATE PROCEDURE wOPGenerareFactura_p @sesiune VARCHAR(50), @parXML XML
AS
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareFactura_pSP')
begin
	exec wOPGenerareFactura_pSP @sesiune = @sesiune, @parXML = @parXML
	return
end

BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE 
		@mesaj VARCHAR(500), @idContract INT, @gestiune VARCHAR(20), @gestiuneRezervari VARCHAR(20), @cuRezervari INT, 	@subunitate VARCHAR(9), @codAvans varchar(20)

	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(20)')

	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	EXEC luare_date_par 'PV','CODAVBEN',0,0,@codAvans OUTPUT


	IF @idContract IS NULL
		RAISERROR ('Nu s-a putut identifica contractul', 11, 1)

	IF OBJECT_ID('tempdb..#pozitiiFactura_p') IS NOT NULL
		DROP TABLE #pozitiiFactura_p

	create table #pozitiiFactura_p(idPozContract int , cod varchar(20), cantitate decimal(15,3), 
		stoc decimal(15,3), in_curs decimal(15,3), rezervat decimal(15,3), facturat decimal(15,3), defacturat decimal(15,3),
		gestiune varchar(50), pret decimal(15,3), discount decimal(15,3), cod_specific varchar(20), cod_intrare varchar(20))

	insert into #pozitiiFactura_p(idPozContract, cod, cantitate, gestiune, pret, discount, cod_specific)
	select	pc.idPozContract, 
			pc.cod,
			pc.cantitate,
			isnull(nullif(convert(varchar(100), pc.detalii.value('/row[1]/@gestiune','varchar(50)')),''), @gestiune) gestiune,
			pret, discount, cod_specific
	from pozContracte pc
	where pc.idContract=@idContract and pc.detalii.value('(/*/@idSursaStorno)[1]','int') is NULL /** pozitiile stornare se ignora aici **/
	
	update pc
		set rezervat = isnull(pd.rezervat, 0),
			facturat = isnull(pd.facturat, 0),
			stoc = isnull(stoc.stoc,0), 
			in_curs = isnull(ic.in_curs,0)
	FROM #pozitiiFactura_p pc
	LEFT JOIN 
	(
		SELECT 
			lc.idPozContract idPozContract, 
			SUM(case when pd.tip in ('AP', 'AS', 'AC') then pd.cantitate else 0 end) facturat,
			SUM(case when pd.tip='TE' AND pd.Gestiune_primitoare = @gestiuneRezervari then pd.cantitate else 0 end) rezervat
		FROM LegaturiContracte lc
		inner join #pozitiiFactura_p pc on lc.idpozcontract=pc.idpozcontract
		LEFT JOIN PozDoc pd ON pd.idPozDoc = lc.idPozDoc AND pd.Tip in ('AP', 'AS', 'AC', 'TE')
		GROUP BY lc.idPozContract
	) pd ON pd.idPozContract = pc.idPozContract
	left join 
	(
		select pc.idPozContract idPozContract, SUM(st.stoc) stoc
		from #pozitiiFactura_p pc
		inner join stocuri st on st.subunitate=@subunitate and st.cod_gestiune=pc.gestiune and pc.cod=st.cod
		group by pc.idpozcontract
	) stoc on pc.idPozContract=stoc.idpozcontract
	left join 
	(
		select pc.idPozContract, SUM(pca.cantitate) in_curs
		from #pozitiiFactura_p pc
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

	UPDATE #pozitiiFactura_p
		SET defacturat = cantitate - facturat
	
	-- apel spre proc. sp care ar putea modifica pe SP lucruri.
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareFactura_p_prelucarePozitii')
		exec wOPGenerareFactura_p_prelucarePozitii @sesiune = @sesiune, @parXML = @parXML
			
	select 
		convert(varchar(10), GETDATE(),101) as data 
	for xml raw, root('Date')

	/*
		Aici vom lua numarul facturii de avans ca si cod intrare pt. a-l trimite la "stornare" si pt. ca sa se inchida situatia cu avansul
	*/
	select pd.cod, pd.cantitate, pd.Pret_valuta pret, pd.Cod_intrare cod_intrare
	into #sit_avans
	from JurnalContracte jc JOIN LegaturiContracte lc on jc.idJurnal=lc.idJurnal and lc.idPozContract IS NULL JOIN PozDoc pd on pd.idPozDoc=lc.idPozDoc and pd.cod=@codAvans and jc.idContract=@idContract

	IF (select sum(cantitate*pret) from #sit_avans)>0.001
	insert into #pozitiiFactura_p (cod, cantitate, pret, cod_intrare)
	select @codAvans, -1, pret, cod_intrare
	from #sit_avans where cantitate*pret>1
	

	SELECT (
			SELECT	
				c.numar numar_contract, @idContract idContract, (case when pf.gestiune = @gestiune then null else pf.gestiune end) gestiune,
				c.valuta valuta, c.tert tert,
				pf.idPozContract idPozContract, rtrim(pf.cod) cod, rtrim(n.denumire) denumire,
				pf.cantitate cantitate, pf.stoc stoc, pf.in_curs, pf.rezervat rezervat, (case when n.tip='S' then pf.cantitate else pf.defacturat end) AS defacturat, 
				pf.facturat facturat, CONVERT(DECIMAL(15, 2), pf.pret) pret,CONVERT(DECIMAL(15, 2), pf.discount) discount, 
				pf.cod_specific cod_specific, pf.cod_intrare cod_intrare
			FROM #pozitiiFactura_p pf			
			JOIN Contracte c on c.idContract=@idContract
			LEFT JOIN nomencl n ON n.cod = pf.cod
			FOR XML raw, type
			)
	FOR XML path('DateGrid'), root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPGenerareFactura_p)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
