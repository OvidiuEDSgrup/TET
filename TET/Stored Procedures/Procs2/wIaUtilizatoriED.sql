
CREATE PROCEDURE wIaUtilizatoriED @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @f_utilizator VARCHAR(50), @f_numeprenume VARCHAR(50), @f_utilizatorwindows VARCHAR(50), @f_grupuri varchar(1)

SET @f_utilizator = '%' + isnull(@parXML.value('(/row/@f_utilizator)[1]', 'varchar(50)'), '') + '%'
SET @f_numeprenume = '%' + isnull(@parXML.value('(/row/@f_numeprenume)[1]', 'varchar(50)'), '') + '%'
SET @f_utilizatorwindows = '%' + isnull(@parXML.value('(/row/@f_utilizatorwindows)[1]', 'varchar(50)'), '') + '%'
SET @f_grupuri = rtrim(isnull(@parXML.value('(/row/@f_grupuri)[1]', 'varchar(1)'), ''))

SELECT RTRIM(ID) AS utilizator, RTRIM(Nume) AS numeprenume, RTRIM(observatii) AS utilizatorwindows, RTRIM(info) AS parolaoffline,
		(case when marca='GRUP' then 'Da' else '' end) as egrupa
FROM utilizatori u
WHERE ID LIKE @f_utilizator
	AND Nume LIKE @f_numeprenume
	AND Observatii LIKE @f_utilizatorwindows
	and (@f_grupuri='' or @f_grupuri='n' and u.Marca<>'GRUP' or @f_grupuri='d' and u.Marca='GRUP')
order by id
FOR XML raw, root('Date')
