
CREATE PROCEDURE wStergPozLansari @sesiune VARCHAR(50), @parXML XML
AS
begin try
	DECLARE @id INT, @comanda VARCHAR(20), @tip VARCHAR(20), @mesaj varchar(max)

	SET @id = @parXML.value('(/row/row/@id)[1]', 'int')
	SET @comanda = @parXML.value('(/row/@comanda)[1]', 'varchar(20)')

	IF isnull((
				SELECT tip
				FROM pozLansari
				WHERE id = @id
				), '') NOT IN ('M', 'O')
	BEGIN
		RAISERROR ('Nu se pot sterge din lansare decat materialele si operatiile (tipuri: M,O)!', 11, 1)
	END

	DELETE
	FROM pozLansari
	WHERE (
			id = @id
			OR idp = @id
			)
		AND tip IN ('M', 'O')

	DECLARE @docXMLIaPozLans XML

	SET @docXMLIaPozLans = '<row comanda="' + rtrim(@comanda) + '"/>'

	EXEC wIaPozLansari @sesiune = @sesiune, @parXML = @docXMLIaPozLans
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wStergPozLansari)'
	raiserror(@mesaj, 11, 1)
end catch
