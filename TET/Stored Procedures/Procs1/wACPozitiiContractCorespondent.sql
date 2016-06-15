
/** Auto-complete folosit in comenzi, atunci cand exista un contract corespondent (ex. CB, CF),
	pentru a specifica doar pozitiile contractului */

CREATE PROCEDURE wACPozitiiContractCorespondent @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE
		@idContract int, @idContractCorespondent int

	SELECT
		@idContract = @parXML.value('(/row/@idContract)[1]', 'int'),
		@idContractCorespondent = NULLIF(@parXML.value('(/row/@idContractCorespondent)[1]', 'int'), '')

	IF @idContract IS NULL
		RAISERROR('Comanda nu s-a putut identifica!', 16, 1)

	IF @idContractCorespondent IS NULL
		RETURN

	SELECT
		pcc.idPozContract as cod,
		ISNULL(RTRIM(n.Denumire), RTRIM(g.Denumire) + ' (grupa)') AS denumire,
		'Cant.: ' + CONVERT(varchar(20), ISNULL(pcc.cantitate, 0)) AS info
	FROM Contracte c
	INNER JOIN Contracte cc ON cc.idContract = c.idContractCorespondent
	INNER JOIN PozContracte pcc ON pcc.idContract = cc.idContract
	LEFT JOIN nomencl n ON n.Cod = pcc.cod
	LEFT JOIN grupe g ON g.Grupa = pcc.grupa
	WHERE c.idContractCorespondent = @idContractCorespondent
		AND c.idContract = @idContract
	FOR XML RAW

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
