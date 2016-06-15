
CREATE PROCEDURE wIaBanci  @sesiune varchar(50), @parXML xml
AS

DECLARE 
	@utilizator varchar(20), @mesaj varchar(100), @f_judet varchar(40), @f_denumire varchar(100)

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT @f_judet = ISNULL(@parXML.value('(/row/@filtrujudet)[1]','varchar(40)'),'%')
	SELECT @f_denumire = ISNULL(@parXML.value('(/row/@filtrudenbanca)[1]','varchar(100)'),'%')

	SELECT 
		RTRIM(b.Cod) AS codbanca, RTRIM(b.Denumire) AS denbanca, RTRIM(b.Filiala) AS filiala,
		RTRIM(ISNULL(j.denumire, b.judet)) AS denjudet, b.Tip AS tip, rtrim(j.cod_judet ) as judet
	FROM bancibnr AS b
	LEFT JOIN Judete AS j ON j.cod_judet = b.Judet
	WHERE b.Judet like '%' + @f_judet + '%' and b.denumire like '%' + @f_denumire + '%'
	ORDER BY b.Denumire
	FOR XML RAW, ROOT('Date')

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wIaBanci)'
	RAISERROR(@mesaj, 11, 1)
END CATCH
