
CREATE PROCEDURE formComandaAprovizionare @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS

DECLARE @debug BIT, @cTextSelect NVARCHAR(max), @idContract INT, @unitate VARCHAR(30), @cui VARCHAR(20), @adr VARCHAR(100), @sediu 
	VARCHAR(100), @judet VARCHAR(100), @cont VARCHAR(100), @banca VARCHAR(100)

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')


SET @unitate = (
		SELECT rtrim(val_alfanumerica)
		FROM par
		WHERE tip_parametru = 'GE'
			AND parametru = 'NUME'
		)
SET @cui = (
		SELECT rtrim(val_alfanumerica)
		FROM par
		WHERE tip_parametru = 'GE'
			AND parametru = 'CODFISC'
		)
SET @adr = (
		SELECT rtrim(val_alfanumerica)
		FROM par
		WHERE tip_parametru = 'GE'
			AND parametru = 'ADRESA'
		)
SET @sediu = (
		SELECT rtrim(val_alfanumerica)
		FROM par
		WHERE tip_parametru = 'GE'
			AND parametru = 'SEDIU'
		)
SET @judet = (
		SELECT rtrim(val_alfanumerica)
		FROM par
		WHERE tip_parametru = 'GE'
			AND parametru = 'JUDET'
		)
SET @cont = (
		SELECT rtrim(val_alfanumerica)
		FROM par
		WHERE tip_parametru = 'GE'
			AND parametru = 'CONTBC'
		)
SET @banca = (
		SELECT rtrim(val_alfanumerica)
		FROM par
		WHERE tip_parametru = 'GE'
			AND parametru = 'BANCA'
		)

SELECT @unitate [UNITATE], @cui [CUI], @adr [ADR], @sediu [SEDIU], @judet [JUDET], @cont [CONT], @banca [BANCA], rtrim(c.numar) [NRCOM], 
	rtrim(t.denumire) AS [BEN], rtrim(t.adresa) AS [ADRESATERT], rtrim(t.localitate) AS [LOCTERT], rtrim(t.judet) AS [JUDTERT], 
	rtrim(convert(CHAR(12), c.data, 104)) AS [DATA], rtrim(row_number() OVER (
			ORDER BY pc.idPozContract
			)) AS [NRCRT], rtrim(pc.cod) AS [COD], rtrim(n.denumire) AS [DEN], rtrim(n.um) AS [UM], rtrim(left(convert(CHAR(16), 
				convert(MONEY, round(pc.cantitate, 2)), 2), 15)) AS [CANT], rtrim(ltrim(convert(CHAR(16), convert(MONEY, round(pc
						.pret, 2), 2), 15))) AS [PRET], rtrim(convert(CHAR(15), convert(MONEY, round(pc.pret * pc.cantitate, 2), 1))
	) AS [VAL], rtrim(convert(CHAR(10), pc.termen, 104)) AS [TERMEN]
INTO #pozitii
FROM Contracte c
INNER JOIN PozContracte pc
	ON pc.idContract = c.idContract
		AND c.idContract = @idContract
LEFT JOIN terti t
	ON t.Tert = c.tert
LEFT JOIN nomencl n
	ON n.Cod = pc.cod
ORDER BY pc.idPozContract

SET @cTextSelect = '
SELECT *
into ' + @numeTabelTemp + '
from #pozitii
'

EXEC sp_executesql @statement = @cTextSelect

IF EXISTS (
		SELECT 1
		FROM sysobjects
		WHERE type = 'P'
			AND NAME = 'formComandaAprovizionareSP1'
		)
BEGIN
	EXEC formComandaAprovizionareSP1 @sesiune = @sesiune, @parXML = @parXML, @numeTabelTemp = @numeTabelTemp OUTPUT
END

IF @debug = 1
BEGIN
	SET @cTextSelect = 'select * from ' + @numeTabelTemp

	EXEC sp_executesql @statement = @cTextSelect
END
