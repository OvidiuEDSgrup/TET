----/** Asociaza ID antet bon din tabelul antetBonuri la coloana idAntetBon din tabela BP acolo unde este NULL **/
----UPDATE bonuriP
----SET bonuriP.IdAntetBon = aBn.idAntetBon
----FROM bp bonuriP
----INNER JOIN antetBonuri aBn ON abn.Casa_de_marcat = bonuriP.Casa_de_marcat
----	AND abn.Numar_bon = bonuriP.Numar_bon
----	AND abn.Data_bon = bonuriP.Data
----WHERE bonuriP.IdAntetBon IS NULL



------update par set Val_alfanumerica='test' where Val_alfanumerica='tet'

----insert par values
----('PO','ORDGEST','',1,0,'')

--IF EXISTS (
--		SELECT *
--		FROM sysobjects
--		WHERE NAME = 'wOPRefacACTE'
--		)
--	DROP PROCEDURE wOPRefacACTE
--GO

---- reface bonurile in in tabela pozdoc, din tabela bp.
--CREATE PROCEDURE wOPRefacACTE @sesiune VARCHAR(50), @parXML XML
--AS
--DECLARE @datajos DATETIME, @datasus DATETIME, @listaGestiuni VARCHAR(max), @Subunitate VARCHAR(1), @Tip VARCHAR(2), @Numar VARCHAR(
--		10), @Cod VARCHAR(10), @Data DATETIME, @Gestiune VARCHAR(10), @Cantitate FLOAT, @Pret_valuta FLOAT, @Pret_de_stoc FLOAT, 
--	@utilizator VARCHAR(50), @stergere BIT, @generare BIT, @databon DATETIME, @casabon VARCHAR(10), @numarbon INT, @UID VARCHAR(50), 
--	@userASiS VARCHAR(50), @msgEroare VARCHAR(max), @codMeniu VARCHAR(2), @vanzator VARCHAR(20), @casamarcat VARCHAR(20), @DetBon 
--	INT, @NrDoc VARCHAR(20)

--BEGIN TRY
--	EXEC luare_date_par 'PO', 'DETBON', @DetBon OUTPUT, 0, ''

--	SET @data = isnull(@parXML.value('(/parametri/@data)[1]', 'datetime'), '01/01/1901')
--	SET @numarbon = isnull(@parXML.value('(/parametri/@numar)[1]', 'int'), '')
--	/*-------- tratat pentru cele doua tipuri de codMeniu RF- Meniu; BC-Document*/
--	SET @datajos = isnull(@parXML.value('(/parametri/@datajos)[1]', 'datetime'), isnull(@data, '01/01/1901'))
--	SET @datasus = isnull(@parXML.value('(/parametri/@datasus)[1]', 'datetime'), isnull(@data, '01/01/1901'))
--	/*--------------------------*/
--	SET @gestiune = isnull(@parXML.value('(/parametri/@gestiune)[1]', 'varchar(10)'), '')
--	SET @codMeniu = isnull(@parXML.value('(/parametri/@codMeniu)[1]', 'varchar(10)'), '')
--	SET @vanzator = isnull(@parXML.value('(/parametri/@vanzator)[1]', 'varchar(10)'), '')
--	SET @casamarcat = isnull(@parXML.value('(/parametri/@casam)[1]', 'varchar(10)'), '')
--	SET @stergere = isnull(@parXML.value('(/parametri/@stergere)[1]', 'bit'), 0)
--	SET @generare = isnull(@parXML.value('(/parametri/@generare)[1]', 'bit'), 0)

--	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

--	IF @Gestiune = ''
--		RAISERROR ('Aceasta operatie se ruleaza pe o gestiune. Alegeti gestiunea dorita.', 11, 1)

--	IF EXISTS (
--			SELECT 1
--			FROM proprietati
--			WHERE Tip = 'UTILIZATOR'
--				AND cod_proprietate IN ('GESTIUNE', 'GESTPV')
--				AND cod = @userASiS
--				AND Valoare <> ''
--			)
--		AND @Gestiune NOT IN (
--			SELECT valoare
--			FROM proprietati
--			WHERE Tip = 'UTILIZATOR'
--				AND cod_proprietate IN ('GESTIUNE', 'GESTPV')
--				AND cod = @userASiS
--			)
--	BEGIN
--		SET @msgEroare = 'Nu aveti dreptul de a rula operatia pe aceasta gestiune (' + @Gestiune + ').'

--		RAISERROR (@msgeroare, 11, 1)
--	END

--	IF @stergere = 0
--		AND @generare = 1
--	BEGIN
--		SET @msgEroare = 'Nu se poate rula generarea documentelor, daca nu bifati si stergerea documentelor existente.'

--		RAISERROR (@msgEroare, 11, 1)
--	END

--	IF @stergere = 1
--	BEGIN
--		IF @codMeniu = 'BC'
--			AND @DetBon = 0
--			RAISERROR ('Bonul nu poate fi sters deoarece nu are detaliere(bonurile se cumuleaza in tabela pozdoc)!', 16, 1
--					)

--		SET @NrDoc = left(RTrim(CONVERT(VARCHAR(4), @casamarcat)) + right(replace(str(@numarbon), ' ', '0'), 4), 8)
--		SET @listaGestiuni = ';' + (
--				SELECT TOP 1 rtrim(val_alfanumerica)
--				FROM par
--				WHERE Tip_parametru = 'PG'
--					AND Parametru = @Gestiune
--				) + ';'

--		DELETE
--		FROM doc
--		WHERE subunitate = '1'
--			AND tip = 'AC'
--			AND stare = 5
--			AND data BETWEEN @datajos
--				AND @datasus
--			AND Cod_gestiune = @gestiune
--			AND (@codMeniu='RF' or Numar = @NrDoc)

--		DELETE
--		FROM pozdoc
--		WHERE subunitate = '1'
--			AND tip = 'AC'
--			AND stare = 5
--			AND data BETWEEN @datajos
--				AND @datasus
--			AND gestiune = @gestiune
--			AND (@codMeniu='RF' or Numar = @NrDoc)

--		DELETE
--		FROM doc
--		WHERE tip = 'AP'
--			AND Stare = 5
--			AND data BETWEEN @datajos
--				AND @datasus
--			AND (@codMeniu='RF' or Numar = @NrDoc)

--		DELETE
--		FROM pozdoc
--		WHERE tip = 'AP'
--			AND Stare = 5
--			AND data BETWEEN @datajos
--				AND @datasus
--			AND (@codMeniu='RF' or Numar = @NrDoc)
--			/*and gestiune=@gestiune gestiunea e in antetbonuri*/
--			AND EXISTS (
--				SELECT 1
--				FROM antetBonuri a
--				WHERE a.Chitanta = 0
--					AND a.Factura = pozdoc.Numar
--					AND a.Gestiune = @Gestiune
--					AND a.Data_facturii = pozdoc.Data
--					AND a.Tert = pozdoc.Tert
--					AND NOT EXISTS (
--						SELECT 1
--						FROM antetBonuri a2
--						WHERE a.factura = a2.factura
--							AND a.data_facturii = a2.data_facturii
--							AND a.tert = a2.tert
--							AND a2.chitanta = 1
--						)
--				)

--		DELETE
--		FROM pozdoc
--		WHERE subunitate = '1'
--			AND tip = 'TE'
--			AND stare = 5
--			AND data BETWEEN @datajos
--				AND @datasus
--			AND gestiune_primitoare = @gestiune
--			--and Gestiune in (select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';') from par where Tip_parametru='PG' and Parametru=@Gestiune )
--			--AND charindex(';' + rtrim(gestiune) + ';', @listagestiuni) > 0
--			AND (@codMeniu='RF' or Numar = @NrDoc)

--		INSERT INTO BT (
--			Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura
--			, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, 
--			Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, idAntetBon, lm_real, Comanda_asis, Contract
--			)
--		SELECT BP.Casa_de_marcat, Factura_chitanta, BP.Numar_bon, Numar_linie, Data, Ora, (CASE Tip WHEN '20' THEN '21' ELSE Tip END
--				), BP.Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, Cantitate, Cota_TVA, Tva, 
--			Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, BP.Loc_de_munca, 
--			Discount, BP.idAntetBon, lm_real, Comanda_asis, BP.Contract
--		FROM BP
--		LEFT JOIN antetBonuri aBon ON aBon.IdAntetBon = bp.IdAntetBon
--		WHERE /*BP.factura_chitanta=1 and*/ BP.data BETWEEN @datajos
--				AND @datasus
--			AND isnull(aBon.Gestiune,bp.Gestiune) = @gestiune
--			AND BP.vinzator = (CASE @codMeniu WHEN 'RF' THEN BP.Vinzator ELSE @vanzator END)
--			AND BP.Casa_de_marcat = (CASE @codMeniu WHEN 'RF' THEN BP.Casa_de_marcat ELSE @casamarcat END)
--			AND BP.Numar_bon = (CASE @codMeniu WHEN 'RF' THEN BP.numar_bon ELSE @numarbon END)

--		DELETE BP
--		FROM bp
--		LEFT JOIN antetBonuri aBon ON aBon.IdAntetBon = bp.IdAntetBon
--		WHERE /*BP.factura_chitanta=1 and*/ BP.data BETWEEN @datajos
--				AND @datasus
--			AND isnull(aBon.Gestiune,bp.Gestiune) = @gestiune
--			AND BP.vinzator = (CASE @codMeniu WHEN 'RF' THEN BP.Vinzator ELSE @vanzator END)
--			AND BP.Casa_de_marcat = (CASE @codMeniu WHEN 'RF' THEN BP.Casa_de_marcat ELSE @casamarcat END)
--			AND BP.Numar_bon = (CASE @codMeniu WHEN 'RF' THEN BP.numar_bon ELSE @numarbon END)
--	END

--	IF @generare = 1
--	BEGIN
--		--select * from pozdoc where data=@datajos and Gestiune=@Gestiune and tip='ac'
--		DECLARE @crsBonuri CURSOR, @status INT, @idBon INT
--			-- apelez descarcarea pentru fiecare bon
--			SET @crsBonuri = CURSOR
--		FOR
--		SELECT DISTINCT bp.idAntetBon
--		FROM bt bp 
--		LEFT JOIN antetBonuri aBon ON aBon.IdAntetBon = bp.IdAntetBon
--		WHERE data BETWEEN @datajos
--				AND @datasus
--			AND isnull(aBon.Gestiune,bp.Gestiune) = @gestiune
--			AND bp.vinzator = (CASE @codMeniu WHEN 'RF' THEN bp.Vinzator ELSE @vanzator END)
--			AND bp.Casa_de_marcat = (CASE @codMeniu WHEN 'RF' THEN bp.Casa_de_marcat ELSE @casamarcat END)
--			AND bp.Numar_bon = (CASE @codMeniu WHEN 'RF' THEN bp.numar_bon ELSE @numarbon END)

--		OPEN @crsBonuri

--		FETCH NEXT
--		FROM @crsBonuri
--		INTO @idBon

--		SET @status = @@fetch_status

--		WHILE @status = 0
--		BEGIN
--			SET @parXML = (
--					SELECT @idBon idAntetBon
--					FOR XML raw
--					)

--			EXEC wDescarcBon @sesiune, @parXML

--			FETCH NEXT
--			FROM @crsBonuri
--			INTO @idBon

--			SET @status = @@fetch_status
--		END
--	END

--	SELECT 'Refacere AC/TE efectuata cu succes!' AS textMesaj
--	FOR XML raw, root('Mesaje')
--END TRY

--BEGIN CATCH
--	DECLARE @eroare VARCHAR(200)

--	SET @eroare = ERROR_MESSAGE() + ('(wOPRefacACTE)')

--	RAISERROR (@eroare, 16, 1)
--END CATCH

--BEGIN TRY
--	-- incerc sa inchid cursoarele doar daca sunt deschise
--	IF CURSOR_STATUS('variable', '@crsBonuri') >= 0
--		CLOSE @crsBonuri

--	IF CURSOR_STATUS('variable', '@crsBonuri') >= - 1
--		DEALLOCATE @crsBonuri
--END TRY

--BEGIN CATCH
--END CATCH
--	/*
---- verific corelare BONURI bp si pozdoc pe o perioada

--select sum(Total)
-- from bp 
--where Factura_chitanta=1 and tip='21'
--and data between '2012-04-10' and '2012-04-10'
--and vinzator='magazin_nt' 

--select SUM(cantitate*Pret_cu_amanuntul) 
--from pozdoc
--where Subunitate='1' and tip='AC' 
--and data between '2012-04-10' and '2012-04-10'
--and pozdoc.Utilizator='magazin_nt'


--*/

CREATE PROCEDURE [dbo].[wOPRecalculareSumeBonuri] @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @dataSusFiltr DATETIME, @gestiuneFiltr VARCHAR(20), @dataJosFiltr DATETIME

SET @dataSusFiltr = @parXML.value('(/*/@datasus)[1]', 'datetime')
SET @dataJosFiltr = @parXML.value('(/*/@datajos)[1]', 'datetime')
SET @gestiuneFiltr = @parXML.value('(/*/@gestiunea)[1]', 'varchar(20)')

IF ISNULL(@gestiuneFiltr, '') = ''
	OR @dataJosFiltr IS NULL
	OR @dataSusFiltr IS NULL
	RAISERROR ('Completati filtrele @gestiune, @datajos si @datasus ', 16, 1)

IF OBJECT_ID('tempdb..#calculate') IS NOT NULL
	DROP TABLE #calculate

/** Iau toate bonurile filtrare cu sumele din tabel + sumele recalculate de mine aplicand discount samd  **/
SELECT casa_de_marcat, numar_bon, data, numar_linie, sum(total) total, sum(cantitate * (pret - (pret * (Discount / 100.0))
			)) * max(Cota_TVA) / (100 + max(Cota_TVA)) tva, MAX(discount) discount, sum(cantitate * (pret - (pret * (Discount / 100.0))
			)) AS totalRecalculat, (CASE WHEN GROUPING(numar_linie) = 1 THEN 'TOTAL' END) tip
INTO #calculate
FROM bp
WHERE tip = '21'
	AND data BETWEEN @dataJosFiltr
		AND @dataSusFiltr
	AND Gestiune = @gestiuneFiltr
	AND Factura_chitanta = '1'
GROUP BY casa_de_marcat, data, numar_bon, numar_linie
WITH rollup

/** Actualizare sume in BP acolo unde au fost gasite diferente provenite de la rotunjiri **/
UPDATE bp
SET bp.total = convert(DECIMAL(15, 2), bp.cantitate * (bp.pret - (bp.pret * (bp.Discount / 100.0))
			)), bp.tva = convert(DECIMAL(15, 2), (
			bp.cantitate * (bp.pret - (bp.pret * (bp.Discount / 100.0))
				)
			) * bp.cota_tva / (100 + bp.cota_tva))
FROM bp
INNER JOIN #calculate c ON c.casa_de_marcat = bp.casa_de_marcat
	AND c.numar_bon = bp.numar_bon
	AND c.data = bp.data
	AND bp.tip = 21
	AND c.tip = 'TOTAL'
	AND abs(c.totalRecalculat - c.total) > 0.01
	AND c.casa_de_marcat IS NOT NULL
	AND c.numar_bon IS NOT NULL
	AND c.data IS NOT NULL
	AND bp.Factura_chitanta = '1'

DECLARE @casa INT, @bon INT, @data DATETIME, @vanzator VARCHAR(20), @gestiune VARCHAR(20), @fStatus INT, @docRefac XML

/** Cursor pentru bonurile care au avut diferente pt refacere **/
DECLARE bonTmp CURSOR
FOR
SELECT c.Casa_de_marcat, c.Numar_bon, c.data, b.Vinzator, b.Gestiune
FROM #calculate c
INNER JOIN bp b ON b.Casa_de_marcat = c.Casa_de_marcat
	AND b.Numar_bon = c.Numar_bon
	AND b.Data = c.Data
	AND c.tip = 'TOTAL'
	AND abs(c.totalRecalculat - c.total) > 0.01
	AND c.casa_de_marcat IS NOT NULL
	AND c.numar_bon IS NOT NULL
	AND c.data IS NOT NULL
GROUP BY c.Casa_de_marcat, c.Numar_bon, c.data, b.Vinzator, b.Gestiune

OPEN bonTmp

FETCH NEXT
FROM bonTmp
INTO @casa, @bon, @data, @vanzator, @gestiune

SET @fStatus = @@FETCH_STATUS

WHILE @fStatus = 0
BEGIN
	/** Apelare refacere AC/TE pentru bonurile de mai sus **/
	SET @docRefac = (
			SELECT @casa '@casam', @gestiune '@gestiune', @bon '@numar', @data '@data', @vanzator '@vanzator', '1' AS '@stergere', '1' 
				AS '@generare', @dataJosFiltr AS '@datajos', @dataSusFiltr AS '@datasus'
			FOR XML path('parametri')
			)

	--EXEC wOPRefacACTE @sesiune = '', @parXML = @docRefac

	FETCH NEXT
	FROM bonTmp
	INTO @casa, @bon, @data, @vanzator, @gestiune

	SET @fStatus = @@FETCH_STATUS
END

CLOSE bonTmp

DEALLOCATE bonTmp
