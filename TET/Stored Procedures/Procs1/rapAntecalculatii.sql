
/** Procedura pentru raportul de set de antecalculatii (Antecalculatii.rdl) ***/
CREATE PROCEDURE [dbo].[rapAntecalculatii] @numarDoc VARCHAR(20)
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT RTRIM(a.Cod) AS cod, RTRIM(n.Denumire) AS denumire, p.cantitate AS cantitate, convert(DECIMAL(15, 6), p.pret) AS pret, RTRIM(n.
		um) AS um, rtrim(n.Grupa) AS grupa, rtrim(gr.denumire) AS dengrupa, a.data AS data
FROM antecalculatii a
JOIN pozAntecalculatii p ON a.idPoz = p.id
JOIN nomencl n ON n.Cod = a.cod
JOIN grupe gr ON gr.grupa = n.grupa
WHERE a.numar = @numarDoc
