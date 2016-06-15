CREATE PROCEDURE wStergPozRapProductie @sesiune VARCHAR(50), @parXML XML
AS
DECLARE 
	@idPozRealizari INT,@eroare varchar(max)


SET @idPozRealizari = ISNULL(@parXML.value('(/row/row/@idPozRealizare)[1]', 'int'), 0)
begin try
	
	DELETE
	FROM pozRealizari
	WHERE id = @idPozRealizari

EXEC wIaPozRapProductie @sesiune = @sesiune, @parXML = @parXML
END TRY

BEGIN CATCH
	SET @eroare = ERROR_MESSAGE()+' (wStergPozRapProductie)'
	RAISERROR (@eroare, 16, 1)
END CATCH


