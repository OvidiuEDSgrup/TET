
/***--
Procedura stocata executa operatia de Import Dispozitii din macheta de preluare dispozitii.
Se citeste in form Tert, Comanda si Grupare si se insereaza in documentul selectat comenzile de aprovizionare
care indeplinesc criteriile din form.

param:	@sesiune	Sesiunea utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@tip		->	Tipul machetei curente (se citeste si trimite mai departe pentru
									identificare in Forms)
					@iddisp		->	Identificator unic al documentului pe care se lucreaza
					@idpoz		->	Identificator unic al pozitiei din document pe care se lucreaza
					@grupare	->	Gruparea din care face parte pozitia inserata/editata
					@tert		->	Tertul completat in textBox-ul de deasupra comenzii
					@comanda	->	Comanda de care apartine produsul
--***/
CREATE PROCEDURE wOPImportDispozitiiAW @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (
		SELECT 1
		FROM sysobjects
		WHERE [type] = 'P'
			AND [name] = 'wOPImportDispozitiiAWSP'
		)
BEGIN
	DECLARE @returnValue INT

	EXEC @returnValue = wOPImportDispozitiiAWSP @sesiune, @parXML OUTPUT

	RETURN @returnValue
END

DECLARE @userASiS VARCHAR(50), @mesaj VARCHAR(1000), @iddisp INT, @docScriere XML, @idComanda INT, @tert VARCHAR(50), @docJurnal XML

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

	-- Preia parametrii XML trimisi 
	SET @iddisp = @parXML.value('(/*/@iddisp)[1]', 'int')
	SET @tert = @parXML.value('(/*/@tert)[1]', 'varchar(50)')
	SET @idComanda = @parXML.value('(/*/@comanda)[1]', 'int')

	-- Daca documentul a fost finalizat nu se mai poate opera
	IF (
			SELECT a.stare
			FROM AntDisp a
			WHERE a.idDisp = @iddisp
			) = 'Finalizat'
		RAISERROR ('Documentul a fost finalizat. Nu se mai pot opera pozitiile.', 11, 1)

	IF ISNULL(@tert, '') = ''
		RAISERROR ('Tertul nu este completat corect', 11, 1)

	IF ISNULL(@idComanda, '') = ''
		RAISERROR ('Nu s-a putut identifica comanda de aprovizionare', 11, 1)

	SET @docScriere = (
			SELECT isnull(w.explicatii, 'Com. pt' + w.tert + ' din ' + CONVERT(VARCHAR(10), w.data, 103)) AS descriere, (
					SELECT w.numar, w.data, w.tert, w.gestiune
					FOR XML raw, type
					) detalii, (
					SELECT cod, cantitate, pret, (
							SELECT idContract idContract, idPozContract idPozContract
							FOR XML raw, type
							) detalii
					FROM PozContracte
					WHERE idContract = @idComanda
					FOR XML raw, type
					)
			FROM Contracte w
			WHERE w.idContract = @idComanda
			FOR XML raw
			)

	IF (
			@iddisp IS NOT NULL
			AND @docScriere IS NOT NULL
			)
		SET @docScriere.modify('insert attribute iddisp {sql:variable("@iddisp")} into (/row)[1]')

	EXEC wScriuPozDispAW @sesiune = @sesiune, @parXML = @docScriere

	SET @docJurnal = (
			SELECT @idComanda idContract, GETDATE() data, 'Importat in dispozitie de receptie' explicatii
			FOR XML raw
			)

	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPImportDispozitiiAW)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
