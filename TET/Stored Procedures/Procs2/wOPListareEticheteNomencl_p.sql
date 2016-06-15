
CREATE PROCEDURE wOPListareEticheteNomencl_p @sesiune varchar(50), @parXML xml
AS

	SELECT
		'/CG/Stocuri/Etichete Nomenclator Fibrex ' AS cale_raport,
		'Etichete nomenclator' AS dencale_raport
	FOR XML RAW
