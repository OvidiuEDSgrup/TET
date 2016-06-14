  
CREATE PROCEDURE wIaPlajeDocumente @sesiune VARCHAR(50), @parXML XML  
AS  
DECLARE @f_tipdocument VARCHAR(20), @f_serie VARCHAR(20), @f_serieinnumar VARCHAR(2)  
  
SET @f_tipdocument = '%' + @parXML.value('(/*/@f_tipdocument)[1]', 'varchar(20)') + '%'  
SET @f_serie = '%' + @parXML.value('(/*/@f_serie)[1]', 'varchar(20)') + '%'  
SET @f_serieinnumar = '%' + @parXML.value('(/*/@f_serieinnumar)[1]', 'varchar(2)') + '%'  
  
SELECT rtrim(df.tipDoc) AS tipdocument, rtrim(df.serie) AS serie, numarInf AS numarinferior, numarSup AS numarsuperior, ultimulnr AS   
 ultimulnumar, rtrim(td.denumire) AS denumire, (CASE isnull(df.serieinnumar, 0) WHEN 0 THEN 'Nu' ELSE 'Da' END) AS   
 denserieinnumar, isnull(df.serieinnumar, 0) AS serieinnumar, df.id as idPlaja  
FROM docfiscale df  
JOIN TipuriDocumente td ON df.TipDoc = td.tip  
WHERE (  
  @f_serieinnumar IS NULL  
  OR (CASE isnull(df.serieinnumar, 0) WHEN 0 THEN 'Nu' ELSE 'Da' END) LIKE @f_serieinnumar  
  )  
 AND (  
  @f_serie IS NULL  
  OR df.serie LIKE @f_serie  
  )  
 AND (  
  @f_tipdocument IS NULL  
  OR df.tipDoc LIKE @f_tipdocument  
  )  
FOR XML raw, root('Date')  