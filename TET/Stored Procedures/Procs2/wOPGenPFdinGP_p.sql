CREATE PROCEDURE wOPGenPFdinGP_p @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @nrdoc VARCHAR(20), @denstare varchar(30),  @data VARCHAR(20), @stare int

SELECT	@nrdoc=ISNULL(@parXML.value('(/row/@numar)[1]','varchar(20)'),''),
		@data=isnull(@parXML.value('(/row/@data)[1]','varchar(30)'),''),
		@denstare=isnull(@parXML.value('(/row/@denstare)[1]','varchar(30)'),''),
		@stare=isnull(@parXML.value('(/row/@stare)[1]','int'),'')
begin TRY 
if @nrdoc=''
	raiserror('Selectati o pozitie!',16,1)
IF @stare<'1'
	RAISERROR ('Documentul este in stare Operabil! Operatie de generare Plata Furnizor nepermisa!',16,1)

SELECT @nrdoc nrdoc, CONVERT(VARCHAR(20),@data,103) data, @denstare stare
FOR XML RAW
END TRY
BEGIN CATCH 
   DECLARE @eroare VARCHAR(500)
   SET @eroare=ERROR_MESSAGE()
   RAISERROR(@eroare,16,1)
END CATCH 