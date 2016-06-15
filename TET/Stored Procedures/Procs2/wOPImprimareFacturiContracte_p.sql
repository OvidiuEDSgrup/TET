
CREATE PROCEDURE wOPImprimareFacturiContracte_p @sesiune varchar(50), @parXML xml
AS
	/** Unele autocomplete-uri tin cont de aceste atribute,
		de aceea trimitem blank. */
	SELECT '' AS tert, '' AS factura, '' AS formular, '' AS data
	FOR XML RAW, ROOT('Date')
