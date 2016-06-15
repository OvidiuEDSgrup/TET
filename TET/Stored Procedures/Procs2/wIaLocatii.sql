
CREATE PROCEDURE wIaLocatii @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE 
		@doc xml	

	exec CalculStocLocatii @sesiune=@sesiune, @parXML=''

	SET @doc = 
	(
		SELECT 
			dbo.wfIaLocatii('', @PARxml)
		for xml path('Ierarhie')
	)

	IF @doc IS NOT NULL
		SET @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

	select @doc FOR XML path('Date')
