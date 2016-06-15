
CREATE PROCEDURE [dbo].[wIaUtilizatori] @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @f_utilizator VARCHAR(20), @f_bd VARCHAR(20), @f_dataii VARCHAR(10), @f_dataie VARCHAR(10), @f_activitatei VARCHAR(10), 
	@f_activitatee VARCHAR(10), @data_jos datetime, @data_sus datetime

SELECT @f_utilizator = '%' + replace(ISNULL(@parXML.value('(/row/@f_utilizator)[1]', 'varchar(20)'), '%'), ' ', '%') + '%', 
	@f_bd = '%' + replace(ISNULL(@parXML.value('(/row/@f_bd)[1]', 'varchar(20)'), '%'), ' ', '%') + '%', 
	@f_dataii = ISNULL(@parXML.value('(/row/@f_dataii)[1]', 'varchar(10)'), '01/01/1901'), 
	@f_dataie = ISNULL(@parXML.value('(/row/@f_dataie)[1]', 'varchar(10)'), '31/12/2999'), 
	@f_activitatei = ISNULL(@parXML.value('(/row/@f_activitatei)[1]', 'varchar(10)'), '01/01/1901'), 
	@f_activitatee = ISNULL(@parXML.value('(/row/@f_activitatee)[1]', 'varchar(10)'), '31/12/2999'),
	@data_jos = isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '01/01/1901'),
	@data_sus = isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '01/01/1901') 

SELECT TOP 100 RTRIM(BD) AS bd, RTRIM(token) AS sesiune, RTRIM(utilizator) AS utilizator, CONVERT(VARCHAR(10), convert(DATETIME, s.
			datai), 103) + ' ' + convert(VARCHAR, convert(DATETIME, s.datai), 8) AS datai, CONVERT(VARCHAR(5), convert(DATETIME, 
			datai), 108) AS orai, CONVERT(VARCHAR(10), s.activitate, 103) + ' ' + convert(VARCHAR(8), s.activitate, 8) AS activitate, 
	CONVERT(VARCHAR(5), convert(DATETIME, activitate), 108) AS oraa, RTRIM(u.nume) AS nume
FROM asisria..sesiuniRIA s
INNER JOIN utilizatori u
	ON s.utilizator = u.ID
WHERE utilizator LIKE @f_utilizator
	AND BD LIKE @f_bd
	--AND s.token <> @sesiune
	AND CONVERT(VARCHAR(10), convert(DATETIME, datai), 103) BETWEEN @f_dataii
		AND @f_dataie
	AND CONVERT(VARCHAR(10), activitate, 103) BETWEEN @f_activitatei
		AND @f_activitatee
/*	AND convert(datetime,convert(VARCHAR(10),s.datai,103)) BETWEEN @data_jos
		AND @data_sus	--< era gresit!!!!!!!! (Luci zice: da eroare!) */
	AND convert(datetime,s.datai) BETWEEN @data_jos
		AND dateadd(d,1,@data_sus)
ORDER BY activitate DESC
FOR XML raw, root('Date')
