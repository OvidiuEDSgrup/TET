
CREATE PROCEDURE wIaArticoleComandaTransport @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@idContract INT, @docXML XML, @f_articol varchar(100), @f_comanda varchar(100)

select
	@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
	@f_articol = '%' +ISNULL(REPLACE(@parXML.value('(/*/@f_articol)[1]', 'varchar(200)'),' ','%'),'%')+'%',
	@f_comanda = '%' +ISNULL(REPLACE(@parXML.value('(/*/@f_comanda)[1]', 'varchar(200)'),' ','%'),'%')+'%'


IF OBJECT_ID('tempdb..#pozitiiContract') IS NOT NULL
	DROP TABLE #pozitiiContract

/** Determinare numar pozitii, rank ... **/
SELECT cod,sum(ISNULL(cantitate,0)) cantitate,rank() OVER (PARTITION BY cod ORDER BY cod) rk,
	1 AS pozitii
INTO #pozitiiContract
FROM PozContracte
WHERE idContract = @idContract
group by cod
UPDATE p
	SET pozitii = ISNULL(pc.nrpoz,0)
from #pozitiiContract p
cross apply (select max(pc.rk) nrpoz from #pozitiiContract pc where pc.cod = p.cod) pc
where p.rk = 1

set @docXML = (
SELECT 
	rtrim(art.cod) AS cod,
	rtrim(n.denumire) AS dencod, 
	rtrim(n.denumire) AS denumire, 
	(CASE WHEN art.pozitii = 1 THEN convert(DECIMAL(15, 2), art.cantitate) END) cantitate,
	rtrim(n.um) AS um,

	(
		SELECT rtrim(term.cod) AS cod,
			isnull(rtrim(n.denumire), term.cod) AS dencod,
			isnull(convert(VARCHAR(100), term.termen, 103), n.denumire) AS denumire, 
			convert(VARCHAR(10), term.termen, 101) termen,
			convert(DECIMAL(15, 2), term.cantitate) cantitate,
			convert(DECIMAL(15, 2), term.pret) pret,
			convert(DECIMAL(15, 2), term.discount) discount,
			term.periodicitate periodicitate,
			dbo.fDenPeriodicitate(term.periodicitate) denperiodicitate,
			rtrim(term.explicatii) explicatii,
			term.idPozContract AS idPozContract,
			rtrim(n.um) AS um,
			convert(DECIMAL(15, 2), n.cota_tva) cotatva,
			term.detalii AS detalii,
			term.detalii detalii,
			liv.numar comandalivrare
		FROM PozContracte term
		INNER join nomencl n on n.cod=term.cod
		CROSS APPLY
		(
			select
				top 1 c.numar, c.data, c.tert
			from LegaturiContracte lc
			JOIN PozContracte pc on lc.idPozContract=term.idPozContract
			JOIN PozContracte pcc on pcc.idPozContract=lc.idPozContractCorespondent
			JOIN Contracte c on c.idContract=pcc.idContract
		) liv
		WHERE term.cod = art.cod and term.idContract=@idContract and liv.numar like @f_comanda
		order by 3
		FOR XML raw,type
	)
FROM #pozitiiContract art
INNER JOIN nomencl n ON n.cod = art.cod
WHERE art.rk = 1 and (n.Denumire like @f_articol or n.cod like @f_articol)
order by n.denumire
FOR XML raw,root('Ierarhie'))

IF @docXML IS NOT NULL
	SET @docXML.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

SELECT @docXML
FOR XML path('Date')

SELECT '1' AS areDetaliiXml
FOR XML raw, root('Mesaje')

--select * from #pozitiiContract
