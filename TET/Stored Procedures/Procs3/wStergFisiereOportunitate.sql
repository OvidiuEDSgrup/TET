
CREATE PROCEDURE wStergFisiereOportunitate @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @idFisier INT, @mesaje VARCHAR(500)

	SET @idFisier = @parXML.value('(/*/@idFisier)[1]', 'int')

	IF @idFisier IS NULL
		RAISERROR ('Nu s-a putut identifica fisierul', 11, 1)

	DELETE TOP (1)
	FROM FisiereOportunitati
	WHERE idFisierOp = @idFisier
END TRY
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
