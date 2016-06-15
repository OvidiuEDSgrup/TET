
CREATE PROCEDURE wStergAntecalculatiiVechi @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE 
		@sterg INT, @mesaj VARCHAR(500), @numar varchar(20), @data datetime

	
	SELECT @sterg = Val_logica
	FROM par
	WHERE parametru = 'ISTANTEC'
	
	IF ISNULL(@sterg ,0)=0
		RETURN

	select
		@numar = @parXML.value('(/*/@numarDoc)[1]','varchar(20)'),
		@data = @parXML.value('(/*/@data)[1]','datetime')

	IF NULLIF(@numar ,'') IS NULL OR NULLIF(@data,'') IS NULL 
		RETURN

	IF OBJECT_ID ('tempdb.dbo.#deSters') IS NOT NULL
		DROP TABLE #deSters

	IF OBJECT_ID ('tempdb.dbo.#articole_curente') IS NOT NULL
		DROP TABLE #articole_curente

	/* Daca se lucreaza asa se sterg antec vechi: ramane doar "antetul" pt. valoare...	*/
	select
		pa.idp as id_tehnologie, pa.id id_antec
	INTO #articole_curente
	from PozAntecalculatii pa
	JOIN Antecalculatii a on pa.tip='A' and pa.id=a.idPoz and a.numar=@numar and a.data=@data

	select
		pa.id id
	INTO #deSters
	from PozAntecalculatii pa 
	JOIN #articole_curente ac on ac.id_tehnologie=pa.idp and pa.tip='A' and pa.id<>ac.id_antec
	 	 
	IF OBJECT_ID ('tempdb.dbo.#deSters') IS NULL
		RETURN

	DELETE pa
	FROM pozAntecalculatii pa
	JOIN #deSters d ON d.id=pa.parinteTop
	
END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergAntecalculatiiVechi)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
