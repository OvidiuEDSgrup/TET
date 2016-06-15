
CREATE PROCEDURE wOPModificareComandaProductie @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare	
		@comanda varchar(20), @idLansare int, @data_lansare datetime, @data_inchidere datetime, @termen datetime, @beneficiar varchar(20), @detalii_comanda XML, 
		@descriere varchar(80), @docJurnal xml

	select
		@comanda = NULLIF(@parXML.value('(/*/@comanda)[1]','varchar(20)'),''),
		@idLansare = NULLIF(@parXML.value('(/*/@idLansare)[1]','int'),0),
		@beneficiar = NULLIF(@parXML.value('(/*/@codtert)[1]','varchar(20)'),''),
		@descriere = NULLIF(@parXML.value('(/*/@descriere)[1]','varchar(80)'),''),
		@data_lansare = @parXML.value('(/*/@dataLansare)[1]', 'datetime'),
		@termen = @parXML.value('(/*/@termen)[1]', 'datetime'),
		@data_inchidere = @parXML.value('(/*/@dataInchidere)[1]', 'datetime')
	
	
	IF @parXML.exist('(/*/detalii/row)[1]') = 1
		SET @detalii_comanda = @parXML.query('/*/detalii/row')

	IF @comanda IS NULL or @idLansare is null
		raiserror ('Nu s-a putut identifica comanda de modificat!',16,1)

		
	update Comenzi set
		beneficiar = (CASE when @beneficiar is null THEN beneficiar ELSE @beneficiar END),
		descriere = (CASE when @descriere is null THEN descriere ELSE @descriere END),
		data_lansarii = (CASE when @data_lansare is null THEN data_lansarii ELSE @data_lansare END),
		numar_de_inventar = CONVERT(varchar(10), (CASE when @termen is null THEN numar_de_inventar ELSE @termen END),111),
		data_inchiderii = (CASE when @data_inchidere is null THEN data_inchiderii ELSE @data_inchidere END)		
	where comanda=@comanda

	update PozLansari set detalii = @detalii_comanda where id=@idLansare
	
	SET @docJurnal =  (select @idLansare idComanda, GETDATE() data, 'Modificare antet comanda' explicatii for xml raw, type)
	EXEC wScriuJurnalComenzi @sesiune = @sesiune, @parXML = @docJurnal

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
