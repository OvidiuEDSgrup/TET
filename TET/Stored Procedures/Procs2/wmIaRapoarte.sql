
CREATE PROCEDURE wmIaRapoarte @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(100), @parentID UNIQUEIDENTIFIER, @searchText VARCHAR(50), @tipItem VARCHAR(2), @areSuperDrept BIT
DECLARE @RapoarteUtilizator TABLE (caleRaport VARCHAR(500))

SET @parentID = @parXML.value('(/row/@itemID)[1]', 'uniqueidentifier')
SET @tipItem = isnull(@parXML.value('(/row/@tipItem)[1]', 'varchar(2)'), '')
SET @searchText = '%' + REPLACE(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(50)'), '%'), ' ', '%') + '%'

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SET @areSuperDrept = dbo.wfAreSuperDrept(@utilizator)

INSERT INTO @RapoarteUtilizator (caleRaport)
SELECT DISTINCT rc.Path
FROM webConfigRapoarte wcr
INNER JOIN ReportServer..CATALOG rc ON wcr.caleRaport = (convert(VARCHAR(500), rc.path) collate SQL_Latin1_General_CP1_CI_AS)
left join fIaGrupeUtilizator(@utilizator) f on wcr.utilizator=f.grupa
WHERE (@areSuperDrept = 1 or f.grupa is not null)

/** Daca e apelarea din meniu iau itemID-ul primului director sistem (care are parinte null) **/
IF @parentID IS NULL
	SELECT @parentID = ItemID
	FROM ReportServer..CATALOG
	WHERE ParentID IS NULL

--Navigare prin structura de directoare
SELECT ItemId AS cod, RTRIM(NAME) AS denumire, (
		CASE WHEN (
					nrDirectoare.suma <> 0
					AND nrRapoarte.suma = 0
					) THEN convert(VARCHAR(3), nrDirectoare.suma) + ' ' + 'Directoare' WHEN (
					nrRapoarte.suma <> 0
					AND nrDirectoare.suma = 0
					) THEN convert(VARCHAR(3), nrRapoarte.suma) + ' ' + 'Rapoarte' WHEN nrRapoarte.suma <> 0
				AND nrDirectoare.suma <> 0 THEN convert(VARCHAR(3), nrDirectoare.suma) + ' ' + 'Directoare si ' + convert(VARCHAR(3)
						, nrRapoarte.suma) + ' ' + 'Rapoarte' WHEN nrRapoarte.suma = 0
				AND nrDirectoare.suma = 0 THEN null END
		) AS info, Path AS cale, '@itemID' AS _numeAtr, type AS tipItem, (CASE WHEN type = '2' THEN 'R' ELSE 'C' END) AS _tipdetalii, (CASE WHEN type = '2' THEN 'wmParametriRaport' END
		) AS _procdetalii, RTRIM(r.NAME) AS nume
into #rapoarte
FROM ReportServer..CATALOG r
INNER JOIN @RapoarteUtilizator c ON r.[Path] = (convert(VARCHAR(500), c.caleRaport) collate SQL_Latin1_General_CP1_CI_AS)
CROSS APPLY (
	SELECT count(1) suma
	FROM ReportServer..CATALOG rr
	INNER JOIN @RapoarteUtilizator c ON rr.[Path] = (convert(VARCHAR(500), c.caleRaport) collate SQL_Latin1_General_CP1_CI_AS
			)
	WHERE ParentID = r.ItemID
		AND type = 1
	) AS nrDirectoare
CROSS APPLY (
	SELECT count(1) suma
	FROM ReportServer..CATALOG rr
	INNER JOIN @RapoarteUtilizator c ON rr.[Path] = (convert(VARCHAR(500), c.caleRaport) collate SQL_Latin1_General_CP1_CI_AS
			)
	WHERE ParentID = r.ItemID
		AND type <> 1
	) AS nrRapoarte
WHERE (
		(
			NAME LIKE @searchText
			AND @searchText <> '%%'
			AND @searchText <> '%%%'
			)
		OR (
			@ParentId IS NULL
			AND ParentId IS NULL
			OR ParentId = @ParentId
			)
		)
	AND EXISTS (
		SELECT 1
		FROM ReportServer..CATALOG r1
		WHERE r1.path LIKE rtrim(r.path) + '%'
			AND r1.Type = 2
		)
	AND NAME LIKE @searchText
ORDER BY NAME

/* In cazul in care avem un singur director intram in el si afisam continutul respectiv*/
if (select count(*) from #rapoarte where tipItem='1')=1
begin
	declare @p3 xml
	set @p3=(select top 1 cod as itemID,1 as tipItem from #rapoarte for xml raw)
	
	exec wmIaRapoarte @sesiune=@sesiune,@parXML=@p3
	return
end
/* Gata problema cu 1 director*/

select * from #rapoarte 
FOR XML raw, root('Date')

SELECT (CASE WHEN @tipItem <> '2' THEN '1' END) AS _areSearch, 'wmIaRapoarte' AS _procdetalii, '1' AS _toateAtr
FOR XML raw, root('Mesaje')
