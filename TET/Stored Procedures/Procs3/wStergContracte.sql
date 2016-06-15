
CREATE PROCEDURE wStergContracte @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@idContract INT, @mesaj VARCHAR(400), @detaliiJurnal XML, @utilizator VARCHAR(100), @docJurnal XML, @stare int, @tip varchar(20)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')

	IF EXISTS (SELECT 1 FROM PozContracte WHERE idContract = @idContract)
		RAISERROR ('Documentul are pozitii!', 11, 1)

	select top 1  @Stare=stare, @tip=tip from JurnalContracte jc join Contracte c on c.idContract=jc.idContract and c.idContract=@idContract order by jc.idJurnal desc
	
	if exists (select 1 from StariContracte where tipContract=@tip and stare=@stare and ISNULL(actaditional,0)=1)
		RAISERROR ('Contractul se afla in starea de act aditional, stare ce nu permite stergerea antetului!', 11, 1)


		
	
	SET @detaliiJurnal = (SELECT GETDATE() AS dataStergere, @utilizator utilizatorStergere, * FROM Contracte WHERE idContract = @idContract FOR XML raw )
	SET @docJurnal = (SELECT @idContract idContract, 'Stergere contract' AS explicatii, GETDATE() AS data, @detaliiJurnal detalii FOR XML raw )

	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal

	UPDATE JurnalContracte
	SET idContract = NULL
	WHERE idContract = @idContract

	DELETE
	FROM Contracte
	WHERE idContract = @idContract
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergContracte)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
