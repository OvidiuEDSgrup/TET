
CREATE PROCEDURE wOPDeschidereInventarPeLocm_p @sesiune varchar(50), @parXML xml
AS
	SELECT '' AS lm, CONVERT(varchar(10), GETDATE(), 101) AS data
	FOR XML RAW, ROOT('Date')
