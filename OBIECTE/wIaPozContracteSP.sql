IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wIaPozContracteSP')
	DROP PROCEDURE wIaPozContracteSP
GO

CREATE PROCEDURE wIaPozContracteSP @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @idContract INT, @cautare VARCHAR(100), @docXML XML, @tip VARCHAR(2), @tert VARCHAR(20) --/*SP
	,@stare int --SP*/

SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
SET @cautare = '%' + @parXML.value('(/row/@_cautare)[1]', 'varchar(100)') + '%'
SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
SET @tert = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
SET @stare = @parXML.value('(/*/@stare)[1]', 'int')

IF OBJECT_ID('tempdb..#pozitiiContract') IS NOT NULL
	DROP TABLE #pozitiiContract

/** Determinare numar pozitii, rank ... **/
SELECT *,
	rank() OVER (PARTITION BY ISNULL(cod,grupa) ORDER BY idPozContract) rk,
	1 AS pozitii
INTO #pozitiiContract
FROM PozContracte
WHERE idContract = @idContract

UPDATE p
	SET pozitii = ISNULL(pc.nrpoz,0)
from #pozitiiContract p
outer apply (select max(pc.rk) nrpoz from #pozitiiContract pc where (pc.cod is null or pc.cod = p.cod) and (pc.grupa is null  or pc.grupa=p.grupa)) pc
where p.rk = 1

/** 
(CASE WHEN art.pozitii = 1 .... end) este tratat la anumite coloane care apar in Contracte (tip CB, CF,CA) pentru cazul in care exista
acelasi cod pe mai multe termene in pozitiile unui contract. La Comenzi (CL) nu se aplica
momenan ordonam dupa denumire
**/
set @docXML = (
SELECT rtrim(ISNULL(art.grupa, art.cod)) AS cod,
	rtrim(ISNULL(convert(varchar(200),g.denumire),n.denumire)) AS dencod, -- denumire pt controale AC
	rtrim(ISNULL(convert(varchar(200),g.denumire),n.denumire)) AS denumire, -- denumire care variaza fata de liniile cu termene
	(CASE WHEN art.pozitii = 1 THEN convert(VARCHAR(10), art.termen, 101) END) termen,
	(CASE WHEN art.pozitii = 1 THEN convert(DECIMAL(15, 2), art.cantitate) END) cantitate,
	(CASE WHEN art.pozitii = 1 THEN convert(DECIMAL(15, 2), art.pret) END) pret,
	(CASE WHEN art.pozitii = 1 THEN convert(DECIMAL(15, 2), art.discount) END) discount,
	(CASE WHEN art.pozitii = 1 THEN art.periodicitate END) periodicitate,
	(CASE WHEN art.pozitii = 1 THEN dbo.fDenPeriodicitate(art.periodicitate) END) denperiodicitate,
	(CASE WHEN art.pozitii = 1 THEN rtrim(art.explicatii) END) explicatii,
	(CASE WHEN art.pozitii = 1 THEN art.idPozContract END) AS idPozContract,
	rtrim(n.um) AS um,
	convert(DECIMAL(15, 2), n.cota_tva) cotatva,
	art.idContract AS idContract,
	@tip tip,
	isnull(art.subtip,@tip) subtip,
	art.detalii AS detalii,
	rtrim(nsp.Cod_special) AS codspecific,
	rtrim(nsp.Denumire) AS dencodspecific,--/*SP
	art.starePoz, denstare=rtrim(sc.denumire), sc.culoare, --SP*/
	(
		SELECT rtrim(term.cod) AS cod,
			isnull(rtrim(n.denumire), term.cod) AS dencod, -- denumire pt controale AC
			isnull(convert(VARCHAR(200), term.termen, 103), n.denumire) AS denumire, /* ref. in order by... -> Daca nu are termen se va afisa denumirea art.  */
			convert(VARCHAR(10), term.termen, 101) termen,
			convert(DECIMAL(15, 2), term.cantitate) cantitate,
			convert(DECIMAL(15, 2), term.pret) pret,
			convert(DECIMAL(15, 2), term.discount) discount,
			term.periodicitate periodicitate,
			dbo.fDenPeriodicitate(term.periodicitate) denperiodicitate,
			rtrim(term.explicatii) explicatii,
			term.idPozContract AS idPozContract,
			isnull(term.subtip,@tip) subtip,
			rtrim(n.um) AS um,
			convert(DECIMAL(15, 2), n.cota_tva) cotatva,
			term.detalii AS detalii,
			rtrim(nsp.Cod_special) AS codspecific,
			rtrim(nsp.Denumire) AS dencodspecific,
			RTRIM(com.cod) comanda_productie, 
			term.detalii detalii
		FROM #pozitiiContract term
		left join nomencl n on n.cod=term.cod
		left join (select cod, max(cod_special) cod_special, max(denumire) denumire from nomspec where tert=@tert group by cod) nsp on term.cod=nsp.cod
		LEFT JOIN pozLansari poz on poz.id=term.idPozLansare
		LEFT JOIN pozLansari com on com.id=poz.parinteTop and com.tip='L' 
		WHERE term.cod = art.cod
			AND (art.pozitii > 1 or (art.pozitii = 1AND term.rk > 1))
		order by 3, art.idPozContract
		FOR XML raw,type
	)
FROM #pozitiiContract art
LEFT JOIN nomencl n ON n.cod = art.cod
left join (select cod, max(cod_special) cod_special, max(denumire) denumire from nomspec where tert=@tert group by cod) nsp on nsp.cod=n.cod
LEFT JOIN Grupe g on g.Grupa=art.grupa --/*SP
LEFT JOIN StariContracte sc on sc.tipContract=@tip and sc.stare=nullif(art.starePoz,@stare) --SP*/
WHERE art.rk = 1
order by --ISNULL(g.denumire,n.denumire), 
	art.idPozContract
FOR XML raw,
	root('Ierarhie')

		)

IF @docXML IS NOT NULL
	SET @docXML.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

SELECT @docXML
FOR XML path('Date')

SELECT '1' AS areDetaliiXml
FOR XML raw, root('Mesaje')

SET @parXML=null

--select * from #pozitiiContract