
CREATE PROCEDURE wOPDefinitivareContract @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	/*Daca la definitivarea contractului se doresc si alte lucruri (validari) anterioare jurnalizarii*/
	IF EXISTS (SELECT * FROM sysobjects	WHERE NAME = 'wOPDefinitivareContractSP')
		exec wOPDefinitivareContractSP @sesiune=@sesiune, @parXML=@parXML

	DECLARE 
		@idContract INT, @stare INT, @mesaj VARCHAR(500), @docJurnal XML
	
	select 
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@stare = @parXML.value('(/*/@stare)[1]', 'int')

	IF @idContract IS NULL
		RAISERROR ('Nu s-a putut identificare comanda/contractul ', 11, 1)

	SET @docJurnal = (SELECT @idContract idContract, 1 stare, GETDATE() AS data, 'Definitivat' AS explicatii FOR XML raw )

	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal

	/*Daca la definitivarea contractului se doresc si alte lucruri*/
	IF EXISTS (SELECT * FROM sysobjects	WHERE NAME = 'wOPDefinitivareContractSP1')
		exec wOPDefinitivareContractSP1 @sesiune=@sesiune, @parXML=@parXML
END TRY

begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
