
CREATE PROCEDURE wIaMasiniTert @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @tert varchar(50), @_cautare varchar(100), @subunitate char(9)
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	
	SELECT @tert = ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(50)'), ''),
		@_cautare = ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(100)'), '')

	SELECT RTRIM(m.Numarul_mijlocului) AS nr_masina,
		RTRIM(m.Descriere) AS descriere_masina,
		RTRIM(m.Delegat) AS delegat,
		RTRIM(t.Descriere) AS dendelegat
	FROM masinexp m
	LEFT JOIN infotert t ON t.Subunitate = 'C' + @subunitate AND t.Tert = @tert AND t.Identificator = m.delegat
	WHERE Furnizor = @tert
		AND (@_cautare = '' OR Numarul_mijlocului like '%' + @_cautare + '%')
	FOR XML RAW, ROOT('Date')

END
