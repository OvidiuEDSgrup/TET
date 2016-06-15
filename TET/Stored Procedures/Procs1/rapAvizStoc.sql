
/**
	Procedura folosita in cadrul raportului (de tip formular) "Aviz stoc", formular folosit ca aviz de insotire marfa.
*/
CREATE PROCEDURE rapAvizStoc @sesiune varchar(50), @data datetime, @gestiune varchar(20) = NULL
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
DECLARE @mesajEroare varchar(500)
select @mesajEroare=''
BEGIN TRY
	DECLARE
		@utilizator varchar(50), @mesaj varchar(300)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	IF OBJECT_ID('tempdb..#stocuri') IS NOT NULL
		DROP TABLE #stocuri
	
	/** Daca nu se specifica in raport o gestiune, se va lua valoarea proprietatii GESTPV */
	IF @gestiune IS NULL
	BEGIN
		SELECT TOP 1 @gestiune = RTRIM(Valoare) FROM proprietati
		WHERE Tip = 'UTILIZATOR' AND Cod = @utilizator AND Cod_proprietate = 'GESTPV'

		/** Daca nu are proprietatea va da eroare. */
		IF ISNULL(@gestiune, '') = ''
		BEGIN
			SET @mesaj = 'Utilizatorul ' + QUOTENAME(@utilizator) + ' nu are asociata proprietatea GESTPV!'
			RAISERROR(@mesaj, 16, 1)
		END
	END
	
	CREATE TABLE #stocuri (subunitate varchar(20), cod varchar(20), gestiune varchar(20),
			pret_cu_amanuntul float, data datetime, stoc float, loc_de_munca varchar(20))

	IF @data IS NULL
	BEGIN
		SET @data = CONVERT(varchar(10), GETDATE(), 101)
		INSERT INTO #stocuri (subunitate, cod, gestiune, pret_cu_amanuntul, data, stoc, loc_de_munca)
		SELECT
			subunitate, cod, RTRIM(cod_gestiune), Pret_cu_amanuntul, data, stoc, loc_de_munca
		FROM stocuri
		WHERE Cod_gestiune = @gestiune
	END
	ELSE
	BEGIN
		DECLARE @parXML xml
		SET @parXML =
		(
			SELECT
				CONVERT(varchar(20), @data, 102) AS ddatajos,
				CONVERT(varchar(20), @data, 102) AS ddatasus,
				@gestiune AS cgestiune,
				1 AS GrCod, 1 AS GrGest, 1 AS GrCodi,
				@sesiune AS sesiune
			FOR XML RAW
		)

		IF OBJECT_ID('tempdb..#docstoc') IS NOT NULL DROP TABLE #docstoc
		CREATE TABLE #docstoc (subunitate varchar(9))
		EXEC pStocuri_tabela

		EXEC pStoc @sesiune = @sesiune, @parXML = @parXML

		INSERT INTO #stocuri (subunitate, cod, gestiune, pret_cu_amanuntul, data, stoc, loc_de_munca)
		SELECT
			subunitate, cod, gestiune, pret_cu_amanuntul, data, stoc, loc_de_munca
		FROM #docstoc
	END

	/** Select principal */
	SELECT
		RTRIM(s.cod) AS cod, MAX(RTRIM(n.Denumire)) AS dencod, MAX(RTRIM(n.UM)) AS um, RTRIM(s.gestiune) AS gestiune,
		MAX(RTRIM(g.Denumire_gestiune)) AS dengestiune, MIN(s.data) AS data, SUM(s.stoc) AS stoc, max(s.pret_cu_amanuntul) AS pret
	FROM #stocuri s
	LEFT JOIN nomencl n ON s.cod = n.Cod
	LEFT JOIN gestiuni g ON s.subunitate = g.Subunitate AND s.gestiune = g.Cod_gestiune
	GROUP BY
		s.cod, s.gestiune--, s.pret_cu_amanuntul
	HAVING
		ABS(SUM(s.stoc)) > 0.001

END TRY
BEGIN CATCH
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
END CATCH

if len(@mesajEroare)>0
select '<EROARE>' as cod, @mesajEroare as dencod
