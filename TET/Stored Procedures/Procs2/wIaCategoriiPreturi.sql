
CREATE PROCEDURE wIaCategoriiPreturi @sesiune varchar(50), @parXML xml
AS

DECLARE
	@utilizator varchar(20), @mesaj varchar(100), @f_dencategorie varchar(30), @f_tipcategorie varchar(20),
	@f_sumadela float, @f_sumapanala float, @areDetalii bit

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT @f_dencategorie = ISNULL(@parXML.value('(/row/@f_dencategorie)[1]','varchar(30)'),'%')
	SELECT @f_tipcategorie = ISNULL(@parXML.value('(/row/@f_tipcategorie)[1]','varchar(20)'),'%')
	SELECT @f_sumadela = ISNULL(@parXML.value('(/row/@f_sumadela)[1]','float'),-99999999)
	SELECT @f_sumapanala = ISNULL(@parXML.value('(/row/@f_sumapanala)[1]','float'),999999999)

	SELECT 
		cp.Categorie AS categoriepret, RTRIM((CASE WHEN cp.Tip_categorie = 1 THEN 'Pret vanzare' WHEN cp.Tip_categorie = 2 THEN 
		'Pret amanunt' WHEN cp.Tip_categorie = 3 THEN 'Discount' END)) AS dentipcategoriepret, 
		cp.Tip_categorie tipcategoriepret,
		RTRIM(cp.Denumire) AS dencategorie, (CASE WHEN cp.In_valuta = 1 THEN 'DA' ELSE 'NU' END) AS invaluta,
		(CASE WHEN cp.Cu_discount = 1 THEN 'DA' ELSE 'NU' END) AS cudiscount, 
		CONVERT(DECIMAL(12,2), cp.Suma) AS suma, 
		cp.categ_referinta AS categref,
		rtrim(c.Denumire)as dencategref,
		cp.detalii AS detalii
	FROM categpret AS cp 
			LEFT JOIN categpret AS c ON cp.categ_referinta = c.Categorie
		WHERE cp.Denumire LIKE '%' + @f_dencategorie + '%'
			AND (CASE WHEN cp.Tip_categorie = 1 THEN 'Pret vanzare' WHEN cp.Tip_categorie = 2 THEN 
			'Pret amanunt' WHEN cp.Tip_categorie = 3 THEN 'Discount' END) LIKE '%' + @f_tipcategorie + '%'
			AND cp.Suma BETWEEN @f_sumadela AND @f_sumapanala
	FOR XML RAW, ROOT('Date')

	SELECT '1' AS areDetaliiXml
	FOR XML RAW, ROOT('Mesaje')

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wIaCategoriiPreturi)'
	RAISERROR(@mesaj, 11, 1)
END CATCH
