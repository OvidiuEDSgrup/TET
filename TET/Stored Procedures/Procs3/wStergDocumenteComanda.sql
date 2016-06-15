
CREATE PROCEDURE wStergDocumenteComanda @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
begin tran 
	DECLARE @mesaj VARCHAR(400), @idContract INT, @idPozContract INT, @idPozDoc INT, @docJurnal XML, @detaliiJurnal XML, @stare INT, 
		@tipDoc VARCHAR(2), @numarDoc VARCHAR(20), @dataDoc DATETIME

	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @idPozDoc = @parXML.value('(/*/@idPozDoc)[1]', 'int')
	SET @idPozContract = @parXML.value('(/*/@idPozContract)[1]', 'int')
	SET @numarDoc = @parXML.value('(/*/@numardoc)[1]', 'varchar(20)')
	SET @dataDoc = @parXML.value('(/*/@data)[1]', 'datetime')

	SELECT @tipDoc = tip
	FROM PozDoc
	WHERE idPozDoc = @idPozDoc

	IF @tipDoc IS NULL
		RAISERROR ('Nu s-a putut identifica pozitia din document marcata pt stergere!', 11, 1)

	SET @detaliiJurnal = (SELECT @idPozContract idPozContract, @idPozDoc idPozDoc FOR XML raw)

	IF (@tipDoc) = 'AP'
	BEGIN
		/** 
			Daca se doreste stergere pozitie factura se realizeaza fara "restrictii"
		**/
		DELETE
		FROM LegaturiContracte
		WHERE idPozContract = @idPozContract
			AND idPozDoc = @idPozDoc

		DELETE
		FROM PozDoc
		WHERE idPozDoc = @idPozDoc

		SELECT @docJurnal = (SELECT @idContract idContract, GETDATE() data, 'Stergere pozitie factura' explicatii, @detaliiJurnal detalii, @stare AS stare FOR XML raw)
		EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT
	END
	ELSE
		IF @tipDoc = 'TE'
		BEGIN
			/**
			Daca se doreste stergerea rezervarilor se verifica daca nu cumva s-a facturat bazat pe aceste rezervari
		**/
			IF EXISTS (
					SELECT 1
					FROM PozContracte pc
					INNER JOIN LegaturiContracte lc ON pc.idContract = @idContract AND pc.idPozContract = lc.idPozContract 
					INNER JOIN PozDoc pd ON pd.idPozDoc = lc.idPozDoc AND pd.Tip = 'AP')
				RAISERROR ('Nu se poate sterge o pozitie din rezervare: s-a facturat bazat pe aceasta rezervare!', 11, 1)

			DELETE
			FROM LegaturiContracte
			WHERE idPozContract = @idPozContract
				AND idPozDoc = @idPozDoc

			DELETE
			FROM PozDoc
			WHERE idPozDoc = @idPozDoc

			SELECT @docJurnal = (
					SELECT @idContract idContract, GETDATE() data, 'Stergere pozitie rezervare' explicatii, @detaliiJurnal detalii, 
						@stare AS stare 
					FOR XML raw)

			EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT
		END
	else
	IF @tipDoc = 'AC'
	begin
		raiserror('Nu se poate sterge o pozitie de tip AC(bon fiscal).', 16 ,1)
	end
	ELSE -- pentru alte tipuri de documente/alte tipuri de contracte
	begin
		SELECT @docJurnal = (
				SELECT @idContract idContract, GETDATE() data, 'Stergere '+@tipDoc explicatii, @detaliiJurnal detalii, @stare AS stare 
				FOR XML raw)
		EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT
		
		DELETE
		FROM LegaturiContracte
		WHERE idPozContract = @idPozContract
			AND idPozDoc = @idPozDoc

		DELETE
		FROM PozDoc
		WHERE idPozDoc = @idPozDoc
	end

	/** 
			Daca nu mai sunt pozitii factura pe aceasta comanda se revine la starea anterioara (tip AP)
			Daca nu mai sunt pozitii AP/TE se sterge si antetul documentului din tabela doc
		**/
	IF NOT EXISTS (
			SELECT 1
			FROM PozContracte pc
			INNER JOIN LegaturiContracte lc
				ON pc.idContract = @idContract
					AND pc.idPozContract = lc.idPozContract
			INNER JOIN PozDoc pd
				ON pd.idPozDoc = lc.idPozDoc
					AND pd.Tip = @tipDoc
			)
	BEGIN
		IF @tipDoc = 'AP'
			SET @stare = 1

		DELETE doc
		WHERE tip = @tipDoc
			AND numar = @numarDoc
			AND data = @dataDoc
	END
	commit tran
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergDocumenteComanda)'

	if @@trancount > 0
		rollback tran

	RAISERROR (@mesaj, 11, 1)
END CATCH
