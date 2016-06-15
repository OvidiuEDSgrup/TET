
CREATE PROCEDURE wOPModificareSumeOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@mesaj VARCHAR(500), @idPozOP INT, @idOP INT, @pozitiiNoi XML, @docJurnal XML

	SET @idPozOP = @parXML.value('(/*/@idPozOP)[1]', 'int')
	SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')

	IF OBJECT_ID('tempdb..#pozitiiNoi') IS NOT NULL
		DROP TABLE #pozitiiNoi

	SELECT 
		P.c.value('@idPozOP', 'int') idPozOP, 
		P.c.value('@suma', 'float') suma,
		P.c.value('@sold', 'float') sold
	INTO #pozitiiNoi
	FROM @parXML.nodes('/*/DateGrid/row') P(c)
	where isnull(P.c.value('@selectat', 'int'),0)=1

	if EXISTS(SELECT 1 from #pozitiiNoi where suma>sold)
		raiserror('Exista facturi pentru care s-a completat o suma mai mare decat soldul!',11,1)

	update po
		set po.suma=(case when pn.suma>pn.sold then pn.sold else pn.suma end ), po.stare='1'
	from PozOrdineDePlata po
	JOIN #PozitiiNoi pn on pn.idPozOp=po.iDPozOp and pn.suma>0.0

	SET @docJurnal = (
			SELECT @idOP idOP, 'Modificare sume ' AS operatie
			FOR XML raw
			)

	EXEC wScriuJurnalOrdineDePlata @sesiune = @sesiune, @parXML = @docJurnal
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPModificareSumeOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
