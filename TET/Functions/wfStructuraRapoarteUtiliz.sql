
--***
CREATE FUNCTION wfStructuraRapoarteUtiliz (@parXML XML, @ParentId UNIQUEIDENTIFIER = NULL)
RETURNS XML
AS
BEGIN
	DECLARE @utilizator VARCHAR(425), @f_nume VARCHAR(425), @f_cale VARCHAR(100)

	SET @f_nume = '%' + isnull(@parXML.value('(/row/@f_nume)[1]', 'varchar(425)'), '') + '%'
	SET @f_cale = '%' + isnull(@parXML.value('(/row/@f_cale)[1]', 'varchar(425)'), '') + '%'
	SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(100)')

	RETURN (
			SELECT @utilizator AS utilizator, r.Path AS caleraport, r.NAME AS nume, r.ItemId AS id, (CASE WHEN wcf.id IS NULL THEN 0 ELSE 1 END
					) AS alocat, dbo.wfStructuraRapoarteUtiliz(@parXML, ItemId), (CASE WHEN wcf.id IS NULL THEN 'Nu' ELSE 'Da' END
					) AS denalocat, (CASE WHEN wcf.id IS NULL THEN '#FF0000' ELSE '#008000' END
					) AS culoare
			FROM ReportServer..CATALOG r
			LEFT JOIN webConfigRapoarte wcf ON wcf.utilizator = @utilizator
				AND r.Path = (convert(VARCHAR(500), wcf.caleRaport) collate SQL_Latin1_General_CP1_CI_AS)
			WHERE ParentId = @ParentId
				AND (
					r.NAME LIKE @f_nume
					AND r.Path LIKE (convert(VARCHAR(500), @f_cale) collate SQL_Latin1_General_CP1_CI_AS
						)
					OR r.Type <> 2
					AND dbo.wfStructuraRapoarteUtiliz(@parXML, ItemId) IS NOT NULL
					)
			FOR XML raw, TYPE
			)
END
	--SELECT dbo.wfStructuraRapoarteUtiliz('526CE271-75A5-46E3-B119-583AC15D6B77')
