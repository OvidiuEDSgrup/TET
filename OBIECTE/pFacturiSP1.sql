-->	procedura pFacturiSP1 (creata din fFacturi) - unifica toate datele financiare din documentele firmei
/*	exemplu de apel:
		1 as cen -> pentru centralizare pe tert, factura
			in acet caz, in loc de #docfacturi se va pune #pFacturiSP1 !
		declare @FurnBenef char(1), @DataJos datetime, @DataSus datetime, @Tert char(13), @Factura char(20), 
				@ContFactura varchar(40), @SoldMin float, @SemnSold int, @StrictPerioada int = 0, @locm varchar(20), @parxml XML
		select @FurnBenef='F',@DataJos='2011-1-1',@DataSus='2014-07-31',@Tert=null,@Factura=null,@ContFactura=null,@SoldMin=0,@SemnSold=0,@StrictPerioada=0,@locm=null
		set @parXML=(select @FurnBenef as furnbenef, @DataJos as datajos, @DataSus as datasus, @tert as tert, @factura as factura, @contfactura as contfactura,
			 @SoldMin as soldmin, @SemnSold as semnsold, @StrictPerioada as strictperioada, @locm as locm for xml raw)
		if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
		create table #docfacturi (furn_benef char(1))
		exec CreazaDiezFacturi @numeTabela='#docfacturi'
		exec pFacturiSP1 @sesiune=null, @parxml=@parXML
		select * from #docfacturi
*/
/*
-->	stergere functie anterioara; cand se va considera se va putea da drumul la stergere. Momentan fFacturi, fFacturiF, fFacturiB s-au mutat in CG\Nepublicabile\Vechi.
if exists (select * from sys.objects where object_id = OBJECT_ID(N'fFacturi') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	drop function fFacturi
--GO
*/
--***
if exists (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'pFacturiSP1') AND type='P')
	drop procedure pFacturiSP1
GO
--***
create procedure pFacturiSP1 @sesiune varchar(50), @parXML xml
as
begin try

	declare @Subunitate char(9), @FurnBenef char(1), @dDataJos datetime, @dDataSus datetime, @Tert char(13),
		@gtert varchar(100),
		@Factura char(20), @ContFactura varchar(40), @SoldMin float, @SemnSold int, 
		@StrictPerioada int, @locm varchar(20), @cen int, @GrTert int, @GrFact int, @GrCont int,
		@dDImpl datetime, @nAnImpl int, @nLunaImpl int, @nAnInitFact int, @IstFactImpl int, @dDataIncDoc datetime, @nAnImplMF int,@nLunaImplMF int, @dDataIncDocMF datetime, 
		@Bugetari int, @Ignor4428Avans int, @Ignor4428DocFF int, @ConturiDocFF varchar(200), @DVI int, @AccImpDVI int, @CtFactVamaDVI int, @GenisaUnicarm int, @PrimariaTM int,
		@DocSchimburi int, @LME int, @IFN int, --@FactBil int, 
		@userASiS varchar(30), @filtrareUser bit, @prelContTVA int, 
		@efecteAchitate bit	--> sa fie aduse facturile achitate prin efecte: 0, null = nu se tine cont, 1 = se aduc cele cu efecte neachitate ca fiind pe sold
		, @lDPreImpl int, @dDPreImpl datetime  -- o setare care spune ca am date initiale anterioare factimpl, tinute in istfact 
		,@indicator varchar(1000)
		,@furn_benef_bin binary(1)	-->	valoarea binara a @furnBenef pt join cu facturi
		,@grupare varchar(4000)	--> grupare custom, experiment; nu se utilizeaza inca
		,@inclFacturiNe bit --/*SP
		,@doarFactComisioane int
		--SP*/

	select @FurnBenef=isnull(@parXML.value('(row/@furnbenef)[1]','varchar(1)'),''),
		@doarFactComisioane=isnull(@parXML.value('(row/@doarFactComisioane)[1]','varchar(1)'),0)
	select @Subunitate=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'')

	IF @FurnBenef = 'F' AND @doarFactComisioane = 1
	BEGIN		
		CREATE NONCLUSTERED INDEX [yso_sub_tip_idpoz]
		ON dbo.#docfac ([subunitate],[tip])
		INCLUDE ([idPozitieDoc])

		DELETE D
		FROM #docfac D LEFT JOIN yso_LegComisionVanzari L ON L.idPozDoc = D.idPozitieDoc
		WHERE D.subunitate=@Subunitate and D.tip in ('RM','RP','RQ','RS') --and D.cont_de_tert<>'' 
			AND L.nrDoc IS NULL
		
		IF OBJECT_ID('tempdb.dbo.#yso_docFacComisioane') IS NOT NULL DROP TABLE #yso_docFacComisioane;
		
		WITH Facturi_comisioane AS (
			SELECT D.factura, D.tert, D.data_facturii, 
				nrCrtFact = ROW_NUMBER() OVER (PARTITION BY D.factura, D.tert ORDER BY D.data_facturii, D.tip, D.data, D.numar, D.numar_pozitie)		
			FROM #DocFac D
			WHERE D.subunitate=@Subunitate and D.tip in ('RM','RP','RQ','RS') /*and D.cont_de_tert<>''*/)
		DELETE D
		FROM #docfac D LEFT JOIN Facturi_comisioane F ON F.factura = D.factura AND F.tert = D.tert and F.nrCrtFact = 1 --AND F.data_facturii = D.data_facturii
		WHERE D.subunitate=@Subunitate and D.tip NOT IN ('RM','RP','RQ','RS') --and D.cont_de_tert<>''
			AND F.factura IS NULL
	END	

	IF OBJECT_ID('tempdb.dbo.#yso_DocVanzComisioaneIntermediari') IS NOT NULL 
	BEGIN
		CREATE NONCLUSTERED INDEX [yso_sub_tip]
		ON dbo.#docfac ([subunitate],[tip])
		INCLUDE ([tert],[factura],[numar],[data],[numar_pozitie],[data_facturii])
		
		DELETE D
		FROM #docfac D LEFT JOIN #yso_DocVanzComisioaneIntermediari V ON D.subunitate = V.subDoc AND D.tip = V.tipDoc AND D.numar = V.nrDoc AND D.data = V.dataDoc
		WHERE D.subunitate=@Subunitate and D.tip in ('AP','AS') --and D.cont_de_tert<>'' 
			AND V.nrDoc IS NULL
		
		IF OBJECT_ID('tempdb.dbo.#yso_docFacComisionate') IS NOT NULL DROP TABLE #yso_docFacComisionate;
		
		WITH Facturi_comisionate AS (
			SELECT D.factura, D.tert, D.data_facturii, 
				nrCrtFact = ROW_NUMBER() OVER (PARTITION BY D.factura, D.tert ORDER BY D.data_facturii, D.tip, D.data, D.numar, D.numar_pozitie)		
			FROM #yso_DocVanzComisioaneIntermediari V JOIN #DocFac D ON D.subunitate = V.subDoc AND D.tip = V.tipDoc AND D.numar = V.nrDoc AND D.data = V.dataDoc
			WHERE D.subunitate=@Subunitate and D.tip in ('AP','AS') /*and D.cont_de_tert<>''*/)
		DELETE D
		FROM #docfac D LEFT JOIN Facturi_comisionate F ON F.factura = D.factura AND F.tert = D.tert AND F.nrCrtFact = 1 --AND F.data_facturii = D.data_facturii
		WHERE D.subunitate=@Subunitate and D.tip NOT IN ('AP','AS') --and D.cont_de_tert<>''
			AND F.factura IS NULL
	END
END TRY

BEGIN CATCH
	DECLARE @mesaj varchar(2000)
	SET @mesaj = ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	RAISERROR (@mesaj, 11, 1)
END CATCH