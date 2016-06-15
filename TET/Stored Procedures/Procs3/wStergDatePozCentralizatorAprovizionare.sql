
CREATE PROCEDURE wStergDatePozCentralizatorAprovizionare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	SET NOCOUNT ON
	declare 
		@idTmp int, @mesaj varchar(max), @cantitate float, @idTmpParinte int

	SELECT
		@idTmp=@parXML.value('(/*/@idTmp)[1]','int'),
		@idTmpParinte=@parXML.value('(/*/@idTmpParinte)[1]','int')
	
	select @cantitate= cantitate from tmpPozArticoleCentralizator where idTmp=@idTmp
	delete FROM tmpPozArticoleCentralizator where idTmp=@idTmp

	update tmpArticoleCentralizator set decomandat=decomandat-@cantitate where idtmp=@idTmpParinte

	exec wIaDatePozCentralizatorAprovizionare @sesiune=@sesiune, @parXML=@parXML
END TRY
BEGIN CATCH
	set @mesaj=ERROR_MESSAGE()+ ' (wStergDatePozCentralizatorAprovizionare)'
	RAISERROR(@mesaj, 11, 1)
END CATCH
