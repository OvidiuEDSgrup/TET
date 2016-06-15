
CREATE PROCEDURE wScriuDatePozCentralizatorAprovizionare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	SET NOCOUNT ON
	declare 
		@mesaj varchar(max), @update bit, @cantitate float, @utilizator varchar(100),@cod varchar(20)

	SELECT
		@cantitate=@parXML.value('(/*/*/@cant_comanda)[1]','float'),
		@cod=@parXML.value('(/*/@cod)[1]','varchar(20)'),
		@update=isnull(@parXML.value('(/*/*/@update)[1]','bit'),0)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	if @update = 1
	begin
		update tmpPozArticoleCentralizator 
			SET cantitate = @cantitate
		where cod=@cod and idPozContract is null and utilizator=@utilizator
	end

	exec wIaDatePozCentralizatorAprovizionare @sesiune=@sesiune, @parXML=@parXML
END TRY
BEGIN CATCH
	set @mesaj=ERROR_MESSAGE()+ ' (wScriuDatePozCentralizatorAprovizionare)'
	RAISERROR(@mesaj, 11, 1)
END CATCH
