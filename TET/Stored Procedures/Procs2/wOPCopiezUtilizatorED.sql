
CREATE PROCEDURE wOPCopiezUtilizatorED @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(10), @numeprenume VARCHAR(30), @windows VARCHAR(100), @rapoarte BIT, @meniuri BIT, @proprietati BIT, @grupe bit,
	@sursa VARCHAR(10), @parola varchar(100), @grupa varchar(100)

SET @utilizator = @parXML.value('(/parametri/@utilizator)[1]', 'varchar(10)')
SET @numeprenume = @parXML.value('(/parametri/@numeprenume)[1]', 'varchar(30)')
SET @windows = @parXML.value('(/parametri/@utilizatorwindows)[1]', 'varchar(100)')
SET @sursa = @parXML.value('(/parametri/@utilizatorsursa)[1]', 'varchar(10)')
SET @rapoarte = @parXML.value('(/parametri/@rapoarte)[1]', 'bit')
SET @meniuri = @parXML.value('(/parametri/@meniuri)[1]', 'bit')
SET @grupe = @parXML.value('(/parametri/@grupe)[1]', 'bit')
SET @parola = @parXML.value('(/parametri/@parolaoffline)[1]', 'varchar(100)')
SET @proprietati = @parXML.value('(/parametri/@proprietati)[1]', 'bit')
set @grupa=(case when isnull(@parXML.value('(/parametri/@egrupa)[1]', 'varchar(2)'),'')='Da' then 'GRUP' else '' end)

BEGIN TRY
	INSERT INTO utilizatori (ID, Nume, Observatii, Parola, Info, Categoria, Jurnal, Marca)
	-- id utilizator trebuie sa fie cu litere mari, pentru a fi recunoscut de PV off-line
	VALUES (upper(@utilizator), @numeprenume, @windows, '', convert(varchar(100),HASHBYTES('MD5',@parola) ,2), '', '', @grupa)

	EXEC copiereUtilizatorED @utilizator = @utilizator, @utilizator_model = @sursa, @meniuri = @meniuri, @rapoarte = @rapoarte, 
		@proprietati = @proprietati, @stergere = 1, @grupe=@grupe
END TRY

BEGIN CATCH
	DECLARE @eroare VARCHAR(250)

	SET @eroare = '(wOPScriuUtilizatorED) Eroare la salvare date: ' + ERROR_MESSAGE()

	RAISERROR (@eroare, 15, 15)
END CATCH
