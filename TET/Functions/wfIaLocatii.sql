
CREATE FUNCTION wfIaLocatii (@codParinte VARCHAR(13), @parXML XML)
RETURNS XML
AS
BEGIN
	DECLARE 
		@f_codlocatie VARCHAR(50), @f_descriere VARCHAR(100), @f_codgestiune VARCHAR(10), @f_dengestiune VARCHAR(100), 
		@f_capJos FLOAT, @f_capSus FLOAT

	select
		@f_codlocatie = '%' + replace(ISNULL(@parXML.value('(/row/@f_codlocatie)[1]', 'varchar(80)'), ''), ' ', '%') + '%',
		@f_descriere = '%' + replace(ISNULL(@parXML.value('(/row/@f_descriere)[1]', 'varchar(80)'), ''), ' ', '%') + '%',
		@f_codgestiune = '%' + replace(ISNULL(@parXML.value('(/row/@f_gestiune)[1]', 'varchar(80)'), ''), ' ', '%') + '%',
		@f_dengestiune = '%' + replace(ISNULL(@parXML.value('(/row/@f_dengest)[1]', 'varchar(80)'), ''), ' ', '%') + '%',
		@f_capJos = ISNULL(@parXML.value('(/row/@f_capacitateJos)[1]', 'float'), 0),
		@f_capSus = ISNULL(@parXML.value('(/row/@f_capacitateSus)[1]', 'float'), 99999999)

	
	RETURN (
			SELECT 
				RTRIM(l.Cod_gestiune) AS gestiune, RTRIM(l.Cod_locatie) AS codlocatie, rtrim(l.descriere) AS descriere,
				RTRIM(g.denumire_gestiune) AS dengestiune, RTRIM(um.Denumire) AS denum, RTRIM(l.um) AS um, 
				CONVERT(DECIMAL(15, 2), l.capacitate) AS capacitate, CONVERT(DECIMAL(15, 2), l.capacitate-st.stoc) AS disponibil, 				
				dbo.wfIaLocatii(l.Cod_locatie, @parXML), rtrim(l.Cod_grup) parinte,  rtrim(pl.Descriere) denparinte
			FROM locatii l
			LEFT JOIN gestiuni g ON g.cod_gestiune = l.Cod_gestiune
			LEFT JOIN locatii pl on pl.Cod_locatie=l.Cod_grup
			LEFT OUTER JOIN um ON um.UM = l.UM
			LEFT OUTER JOIN tmpStocPeLocatii st on l.cod_locatie=st.cod_locatie
			WHERE 
				ISNULL(l.Cod_grup,'') = @codParinte
				AND 
				(
					(
						l.cod_locatie LIKE @f_codlocatie
						AND l.Descriere LIKE @f_descriere
						AND l.Cod_gestiune LIKE @f_codgestiune
						AND l.Capacitate BETWEEN @f_capJos
							AND @f_capSus
						AND ISNULL(g.Denumire_gestiune,'') LIKE @f_dengestiune
					)
				OR dbo.wfIaLocatii(l.Cod_locatie, @parXML) IS NOT NULL
				)

			FOR XML raw, type
			)
END
