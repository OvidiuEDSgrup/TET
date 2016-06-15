/* Procedura de aducere a locatiilor pentru raportul Locatii + codurile QR */
CREATE PROCEDURE rapLocatiiQR @sesiune varchar(50), @gestiune varchar(50), @codLocatie varchar(30)
AS

BEGIN TRY	
	DECLARE 
		@mesaj varchar(200), @utilizator varchar(20)

	exec CalculStocLocatii @sesiune=@sesiune, @parXML=''

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	IF @codLocatie IS NULL OR @codLocatie = '' -- aici se verifica daca codul locatiei introdus este null sau blank
	BEGIN									   -- si in caz afirmativ, se intoarce intreaga lista de locatii, filtrata pe gestiune
		SELECT 
			rtrim(l.Cod_locatie) Cod_locatie, rtrim(l.Cod_grup) Cod_grup, rtrim(l.UM) UM, convert(decimal(15,2),Capacitate) Capacitate, 
			ISNULL(rtrim(g.Denumire_gestiune), '') AS Gestiune,	ISNULL(rtrim(l.Cod_gestiune), '') AS Cod_gestiune, 
			rtrim(l.Descriere) Descriere, convert(decimal(15,2),Capacitate-st.stoc) Disponibil 
		FROM locatii l
		LEFT JOIN gestiuni g ON l.Cod_gestiune = g.Cod_gestiune
		LEFT JOIN tmpStocPeLocatii st on l.Cod_locatie=st.cod_locatie
		WHERE l.Cod_gestiune like RTRIM(ISNULL(@gestiune, '')) + '%'
		RETURN
	END

	;WITH a
	AS 
	( 
		SELECT 
			Cod_locatie, Cod_grup, UM, Capacitate, Cod_gestiune, Descriere, 1 AS depth
			FROM locatii WHERE @codLocatie = Cod_locatie
			UNION ALL
			SELECT 
				l.Cod_locatie, l.Cod_grup, l.UM, l.Capacitate, l.Cod_gestiune, l.Descriere, a.depth + 1 AS 'Nivel'
			FROM locatii l
			INNER JOIN a ON a.Cod_locatie = l.Cod_grup
	)

	/* aici se intoarce lista de locatii in functie de codul locatiei dat ca argument,
	   impreuna cu nodurile care fac parte din locatia data (structura arborescenta)
	*/

	SELECT 
		rtrim(a.Cod_locatie) Cod_locatie, rtrim(a.Cod_grup) Cod_grup, rtrim(UM) UM, convert(decimal(15,2),Capacitate) Capacitate, 
		ISNULL(rtrim(g.Denumire_gestiune), '') AS Gestiune, ISNULL(rtrim(a.Cod_gestiune), '') AS Cod_gestiune, 
		rtrim(a.Descriere) Descriere, convert(decimal(15,2),a.Capacitate-st.stoc) Disponibil
	FROM a
	LEFT JOIN gestiuni g ON a.Cod_gestiune = g.Cod_gestiune
	LEFT JOIN tmpStocPeLocatii st on a.Cod_locatie=st.cod_locatie
	WHERE a.Cod_gestiune like RTRIM(ISNULL(@gestiune, '')) + '%' -- filtru pe codul gestiunii

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (rapCoduriQR)'
	RAISERROR(@mesaj, 11, 1)
END CATCH

/*
exec rapLocatiiQR @sesiune='', @gestiune = '', @codLocatie = ''
*/
