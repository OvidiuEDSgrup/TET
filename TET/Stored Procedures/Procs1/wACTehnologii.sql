
CREATE PROCEDURE wACTehnologii @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE 
		@search VARCHAR(200), @tip_tehnologie varchar(20)

	select
		@search = '%' + replace(@parXML.value('(/row/@searchText)[1]', 'varchar(200)'), ' ', '%') + '%',
		@tip_tehnologie = @parXML.value('(/row/@tip_tehnologie)[1]', 'varchar(20)')

		SELECT TOP 100 
			RTRIM(cod) AS cod, RTRIM(denumire) AS denumire, 
			'Tip: ' + (CASE tip when 'P' THEN 'Produs' WHEN 'R' THEN 'Reper' WHEN 'S' THEN 'Serviciu' WHEN 'M' THEN 'Multipla' WHEN 'I' THEN 'Interventie' when 'F' then 'Faza' END) AS info
		FROM tehnologii
		WHERE (codNomencl like @search OR cod LIKE @search OR Denumire LIKE @search ) and (@tip_tehnologie IS NULL or tip=@tip_tehnologie)
		FOR XML raw, root('Date')
