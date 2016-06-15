
CREATE PROCEDURE wScriuPlanificareGantt @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE 
		@id INT, @dataStart DATETIME, @dataStop DATETIME, @oraStop VARCHAR(4), @oraStart VARCHAR(4), @mesaj VARCHAR(300),
		@resursa int

BEGIN TRY
	select
		@id = @parXML.value('(/*/@id)[1]', 'int'),
		@dataStart = @parXML.value('(/*/@dataStart)[1]', 'datetime'),
		@dataStop = @parXML.value('(/*/@dataStop)[1]', 'datetime'),
		@oraStart = replace(@parXML.value('(/*/@oraStart)[1]', 'varchar(5)'), ':', ''),
		@oraStop = replace(@parXML.value('(/*/@oraStop)[1]', 'varchar(5)'), ':', ''),
		@resursa = @parXML.value('(/*/@resursa)[1]', 'int')

	UPDATE planificare
		SET dataStart = @dataStart, dataStop = @dataStop, oraStart = @oraStart, oraStop = @oraStop, resursa=@resursa
	WHERE id = @id
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPlanificareGantt)'
	RAISERROR (@mesaj, 11, 1)
END CATCH

