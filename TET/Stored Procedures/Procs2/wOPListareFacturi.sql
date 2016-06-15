
CREATE PROCEDURE wOPListareFacturi @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare @mesaj varchar(500), @numefisier varchar(100), @formular varchar(20)
	
	/** Formularul folosit este cel ales in macheta **/
	set @formular = @parXML.value('(/*/@formular)[1]','varchar(20)')
	if @formular is null
		raiserror('Nu s-a ales formularul!',11,1)
	/** Nume fisier= Facturi+ sesiunea curenta pt diferentiere **/
	set @numefisier='Facturi '+@sesiune

	/** Se pregateste apelul wTipFormular **/
	SET @parXML.modify('insert attribute nrform {sql:variable("@formular")} into (/*[1])')
	SET @parXML.modify('insert attribute numefisier {sql:variable("@numefisier")} into (/*[1])')

	
	EXEC wTipFormular @sesiune = @sesiune, @parXML = @parXML
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPListareFacturi)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
