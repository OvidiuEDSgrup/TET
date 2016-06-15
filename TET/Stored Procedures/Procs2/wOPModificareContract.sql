
CREATE PROCEDURE wOPModificareContract @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareContractSP')
		exec wOPModificareContractSP @sesiune = @sesiune, @parXML = @parXML output

	DECLARE 
		@docJurnal XML, @idContract INT, @tert VARCHAR(20), @lm VARCHAR(20), @gestiune VARCHAR(20),@explicatiiJurnal VARCHAR(60), 
		@detaliiJurnal XML, @data DATETIME, @detaliiContract XML, @gestiune_primitoare VARCHAR(20), @valuta VARCHAR(20), 
		@curs FLOAT, @explicatiiContract VARCHAR(8000), @punct_livrare VARCHAR(20), @stare INT,@tipContract VARCHAR(2),@valabilitate datetime, 
		@numar varchar(20)

	/** Identificarea contractului dupa ID **/
	SELECT
		@tipContract = @parXML.value('(/*/@tip)[1]', 'varchar(2)'),
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@stare = @parXML.value('(/*/@stare)[1]', 'int')

	IF @idContract IS NULL
		RAISERROR ('Nu s-a putut identifica contractul', 11, 1)

	IF (SELECT TOP 1 modificabil FROM StariContracte WHERE tipContract = @tipContract AND stare = @stare ) <> 1
		RAISERROR ('Documentul este intr-o stare care nu permite modificarea!', 11, 1)

	SELECT		
		@data = @parXML.value('(/*/@data)[1]', 'datetime'),
		@valabilitate = @parXML.value('(/*/@valabilitate)[1]', 'datetime'),
		@numar = NULLIF(@parXML.value('(/*/@numar)[1]', 'varchar(20)'),''),
		@tert = NULLIF(@parXML.value('(/*/@tert)[1]', 'varchar(20)'),''),
		@punct_livrare = NULLIF(@parXML.value('(/*/@punct_livrare)[1]', 'varchar(20)'),''),
		@lm = NULLIF(@parXML.value('(/*/@lm)[1]', 'varchar(20)'),''),
		@gestiune = NULLIF(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'),''),
		@gestiune_primitoare = NULLIF(@parXML.value('(/*/@gestiune_primitoare)[1]', 'varchar(20)'),''),
		@valuta = @parXML.value('(/*/@valuta)[1]', 'varchar(20)'),
		@curs = NULLIF(@parXML.value('(/*/@curs)[1]', 'float'), 0),
		@explicatiiContract = NULLIF(@parXML.value('(/*/@explicatii)[1]', 'varchar(8000)'),''), 
		/*	Daca nu se primeste in variabila alta explicatie pentru modificare ( de ex: 'Reziliere' ) se va nota standard 'Modificare'	*/
		@explicatiiJurnal = ISNULL(NULLIF(@parXML.value('(/*/@explicatiiJurnalizare)[1]', 'varchar(60)'),''),'Modificare')
		
	IF @parXML.exist('(/*/detalii/row)[1]') = 1
		SET @detaliiContract = @parXML.query('/*/detalii/row')

	/*	In detalii XML se va salva antetul contractului inainte de modificare	*/
	SELECT
		@detaliiJurnal = (SELECT *FROM Contracte WHERE idContract = @idContract	FOR XML raw)

	UPDATE Contracte SET 
		numar=(CASE WHEN @numar IS NULL THEN numar ELSE @numar END),
		data = (CASE WHEN @data IS NULL THEN data ELSE @data END), 
		tert = (CASE when @tert is null THEN tert ELSE @tert END),		 
		punct_livrare = (CASE WHEN @punct_livrare IS NULL THEN punct_livrare ELSE @punct_livrare END),
		loc_de_munca = (CASE WHEN @lm IS NULL THEN loc_de_munca ELSE @lm END), 
		gestiune = (CASE WHEN @gestiune IS NULL THEN gestiune ELSE @gestiune END),
		gestiune_primitoare = (CASE WHEN @gestiune_primitoare IS NULL THEN gestiune_primitoare ELSE @gestiune_primitoare END), 
		valabilitate=(CASE WHEN @valabilitate IS NULL THEN valabilitate ELSE @valabilitate END),		
		valuta = (CASE WHEN @valuta IS NULL THEN valuta ELSE nullif(@valuta, '') END),
		curs = (CASE WHEN @curs=0 THEN curs WHEN @curs IS NULL THEN curs ELSE @curs END), 
		explicatii = (CASE WHEN @explicatiiContract IS NULL THEN explicatii ELSE @explicatiiContract END),
		detalii = (CASE WHEN @detaliiContract IS NULL THEN detalii ELSE @detaliiContract END)
	WHERE idContract = @idContract

	SET @docJurnal = (SELECT @idContract idContract, GETDATE() data, @explicatiiJurnal explicatii, @detaliiJurnal detalii, @stare stare	FOR XML raw)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
