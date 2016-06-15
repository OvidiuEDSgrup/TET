
CREATE PROCEDURE wIaFacturiAgent @sesiune VARCHAR(20), @parXML XML
AS
if exists(select * from sysobjects where name='wIaFacturiAgentSP' and type='P')  
begin
	exec wIaFacturiAgentSP @sesiune, @parXML   
	return 0
end

DECLARE @utilizator VARCHAR(100), @lm VARCHAR(50), @facturi XML

--Variabila XML facturi va asigura urmatorul lucru: dupa ce se salveaza datele pe server, clientul nu asteapta procesarea lor ci 
--isi ia alte date, insa in aceasta situatie facturile incasate de agent nu apuca sa fie procesate de proceduri si clientul
--le va lua din noi la sincronizare desi ele au fost practic "procesate". In acest fel prin legatura cu @facturi vom asigura
--ca facturile trimise in aceasta sesiune de sincronizare nu vor mai fi date agentului
EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SET @lm = isnull(dbo.wfProprietateUtilizator('LOCMUNCA', @utilizator), '')
SET @facturi = (
		SELECT TOP 1 DATE.query('Date/Facturi/row')
		FROM logSincronizare
		WHERE utilizator = @utilizator
		)

SELECT rtrim(f.factura) AS cod, RTRIM(f.tert) AS tert, ltrim(convert(CHAR(20), convert(DECIMAL(12, 2), f.valoare + f.TVA_11 + f.TVA_22
			), 1)) AS suma, ltrim(convert(CHAR(20), convert(DECIMAL(12, 2), f.achitat), 1)) AS achitat, 0 AS incasat, 'Factura: ' + 
	rtrim(f.factura) + ' din ' + convert(CHAR(10), f.data, 103) AS denumire, convert(VARCHAR(4), f.tip) AS tip, 'Val:' + LTRIM(convert(
			CHAR(20), convert(MONEY, f.valoare + f.TVA_11 + f.TVA_22), 1)) + ',Ach:' + LTRIM(convert(CHAR(20), convert(MONEY, f.
				achitat), 1)) AS info
FROM facturi f
INNER JOIN terti t ON f.Subunitate = t.Subunitate AND f.Tert = t.Tert
LEFT JOIN infotert it ON it.subunitate = t.subunitate AND it.tert = t.tert AND it.identificator = ''
LEFT JOIN @facturi.nodes('row') lf(c) ON lf.c.value('@cod', 'varchar(20)') = f.Factura
	AND lf.c.value('@tert', 'varchar(20)') = f.Tert
WHERE 1=1
	and it.loc_munca = @lm
	AND ABS(sold) > 0.009
	AND isnull(lf.c.value('@cod', 'varchar(20)'), '') = ''
FOR XML raw
