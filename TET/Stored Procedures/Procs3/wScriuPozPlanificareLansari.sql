
CREATE PROCEDURE wScriuPozPlanificareLansari @sesiune VARCHAR(50), @parXML XML
AS
begin try
	DECLARE @codOp VARCHAR(20), @comanda VARCHAR(20), @codRes VARCHAR(20), @idPlan INT, @dataStart DATETIME, @dataStop DATETIME, 
		@cantitate FLOAT, @update BIT, @idOp INT, @ore FLOAT, @cantitateFinala FLOAT, @cant_o FLOAT, @oraStop VARCHAR(5), @oraStart VARCHAR
		(5), @cant_max FLOAT, @mesaj varchar(max)

	--Identificatori  
	SET @codOp = ISNULL(@parXML.value('(/row/linie/@codOperatie)[1]', 'varchar(20)'), '')
	SET @idPlan = ISNULL(@parXML.value('(/row/linie/@idPlanif)[1]', 'int'), 0)
	SET @idOp = @parXML.value('(/row/linie/@id)[1]', 'int')
	SET @comanda = @parXML.value('(/row/@comanda)[1]', 'varchar(20)')
	--Timpi  
	SET @dataStart = @parXML.value('(/row/row/@dataStart)[1]', 'datetime')
	SET @dataStop = @parXML.value('(/row/row/@dataStop)[1]', 'datetime')
	SET @oraStart = replace(ISNULL(@parXML.value('(/row/row/@oraStart)[1]', 'varchar(5)'), 0), ':', '')
	SET @oraStop = replace(ISNULL(@parXML.value('(/row/row/@oraStop)[1]', 'varchar(5)'), 0), ':', '')
	SET @cantitate = ISNULL(@parXML.value('(/row/row/@cantitate)[1]', 'float'), 0)
	--Alte  
	SET @update = ISNULL(@parXML.value('(/row/row/@update)[1]', 'bit'), 0)
	--La adaugare linie= informatii operatie si comanda  
	--La modificare linie=informatii planificare  
	SET @codRes = @parXML.value('(/row/row/@codResursa)[1]', 'varchar(20)')
	
	--SELECT TOP 1 @idOp = lansare.id
	--FROM pozLansari antetLans
	--INNER JOIN pozLansari lansare ON antetLans.tip = 'L'
	--	AND antetLans.cod = @comanda
	--	AND lansare.tip = 'O'
	--	AND antetLans.id = lansare.parinteTop
	--WHERE lansare.cod = @codOp

	IF @update = 1
	BEGIN
		UPDATE planificare
		SET dataStart = @dataStart, dataStop = @dataStop, cantitate = @cantitate, resursa = @codRes, oraStart = @oraStart, oraStop = @oraStop
		WHERE id = @idPlan
	END
	ELSE
		IF @update = 0
		BEGIN
			INSERT INTO planificare (idOp, resursa, comanda, dataStart, dataStop, oraStart, oraStop, cantitate, stare)
			VALUES (@idOp, @codRes, @comanda, @dataStart, @dataStop, @oraStart, @oraStop, @cantitate, 'P')
		END

	DECLARE @docXMLIaPozPlanificareLansar XML

	SET @docXMLIaPozPlanificareLansar = '<row comanda="' + rtrim(@comanda) + '"/>'

	EXEC wIaPozPlanificareLansari @sesiune = @sesiune, @parXML = @docXMLIaPozPlanificareLansar
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wScriuPozPlanificareLansari)'
	raiserror(@mesaj, 11, 1)
end catch
