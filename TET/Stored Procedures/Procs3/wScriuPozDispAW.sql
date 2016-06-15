
/***--
Procedura stocata scrie date in PozDispOp, creeaza antet in AntDisp in caz ca acesta nu exista pentru legarea
dispozitiilor de aprovizionare de un document propriu-zis si seteaza starea 'Operat' dispozitiei inserate daca
aceasta a primit si o grupare.

param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@tip		->	Tipul machetei curente (se citeste si trimite mai departe pentru
									identificare in Forms)
					@descriere	->	Descrierea care se afla in antetul documentului
					@iddisp		->	Identificator unic al documentului pe care se lucreaza
					@idpoz		->	Identificator unic al pozitiei din document pe care se lucreaza
					@cod		->	Codul de nomencl care identifica produsul
					@cantitate	->	Numarul de produse
					@pret		->	Pretul produsului
					@comanda	->	Comanda de care apartine produsul
					@update		->	Daca e 1 inseamna ca se face editare pe o linie existenta,
									daca nu exista inseamna ca e inserare linie noua
--***/
CREATE PROCEDURE wScriuPozDispAW @sesiune VARCHAR(50), @parXML XML
AS
-- apelare procedura specifica daca aceasta exista.
IF EXISTS (
		SELECT 1
		FROM sysobjects
		WHERE [type] = 'P'
			AND [name] = 'wScriuPozDispAWSP'
		)
BEGIN
	DECLARE @returnValue INT

	EXEC @returnValue = wScriuPozDispAWSP @sesiune, @parXML OUTPUT

	RETURN @returnValue
END

DECLARE @userASiS VARCHAR(50), @mesaj VARCHAR(100), @iddisp INT, @idpoz INT, @o_cod VARCHAR(50), @cod VARCHAR(50), @cantitate FLOAT, 
	@pret FLOAT, @comanda VARCHAR(50), @descriere VARCHAR(200), @update INT, @tip VARCHAR(2), @stareAntet VARCHAR(50),
	-- Folosit pentru verificarea starii antetului documentului
	/*Folosite pentru salvarea datelor din pozitia curenta si identificarea pozitiei cu aceleasi informatii */
	@newIdPoz INT, @nrDoc VARCHAR(50), @dataDoc VARCHAR(30), @tipDoc VARCHAR(10), @detaliiAntet XML, @detaliiPoz XML,
	@cantitate_diferenta float

BEGIN TRY
	/*Validare utilizator*/
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

	/*Preia parametrii XML trimisi */
	SET @update = ISNULL(@parXML.value('(/row/row/@update)[1]', 'int'), 0)
	SET @o_cod = isnull(@parXML.value('(/row/row/@o_cod)[1]', 'varchar(50)'), '')

	SELECT Antete.ant.value('@descriere', 'varchar(50)') descriere, Antete.ant.value('@iddisp', 'int') iddisp, Antete.ant.query
		('(detalii/row)[1]') detalii
	INTO #AntetDispTmp
	FROM @parXML.nodes('/*') Antete(ant)

	SELECT Pozitii.poz.value('@cod', 'varchar(20)') cod, Pozitii.poz.value('@idpoz', 'int') idpoz, Pozitii.poz.value(
			'@cantitate', 'float') cantitate, Pozitii.poz.value('@pret', 'float') pret, 0 as cantitate_scanata,
		Pozitii.poz.query('(detalii/row)[1]') detalii
	INTO #PozDispTmp
	FROM @parXML.nodes('/*/row') Pozitii(poz)

	SELECT @iddisp = iddisp
	FROM #AntetDispTmp

	SELECT TOP 1 @iddisp = iddisp
	FROM #AntetDispTmp

	/*Daca documentul a fost finalizat nu se mai poate opera */
	IF (
			(
				SELECT a.stare
				FROM AntDisp a
				WHERE a.idDisp = @iddisp
				) = 'Finalizat'
			)
		RAISERROR ('Documentul a fost finalizat. Nu se mai poate opera.', 11, 1)

	IF @update = 0 -- inserare linie noua
	BEGIN
		/*Daca nu este generat antet se genereaza (intrare noua) */
		IF (@iddisp IS NULL)
		BEGIN
			INSERT INTO AntDisp (tipDisp, stare, detalii, utilizator, descriere, dataUltimeiOperatii)
			SELECT 'FC', 'In operare', detalii, @userASiS, descriere, GETDATE()
			FROM #AntetDispTmp

			/*Citesc id-ul ultimei iserari pentru legarea documentului de acest antet */
			SELECT @iddisp = IDENT_CURRENT('AntDisp')
		END
			
		/*inserare atribut cantitate_diferenta(diferenta intre scanat si operat), 
			in cazul adaugarii unei noi pozitii din macheta de despozitii de receptie, cantitatea va fi egala cu cantitatea introdusa*/
		update #PozDispTmp set detalii= case when isnull(convert(varchar(max),detalii),'')='' 
			then convert(xml,'<row cantitate_diferenta="0" explicatii_diferenta="pozitie adaugata din ASiSria" />') 
			else detalii end
		
		UPDATE #PozDispTmp
		SET detalii.modify ('replace value of (/row/@cantitate_diferenta)[1] with sql:column ("cantitate")')		
		
		--Insereaza datele propriu-zise in tabela PozDispOp si face update pe antet la data ultimei operatii
		INSERT INTO PozDispOp (idDisp, cod, cantitate, pret, detalii, utilizator, data_operarii)
		SELECT @iddisp, cod, cantitate, pret, detalii, @userASiS, getdate()
		FROM #PozDispTmp
	END
	ELSE -- mod editare linie existenta
	BEGIN
		SET @cod = @parXML.value('(/row/row/@cod)[1]', 'varchar(50)')
		SET @cantitate = @parXML.value('(/row/row/@cantitate)[1]', 'float')
		SET @pret = @parXML.value('(/row/row/@pret)[1]', 'float')
		SET @idpoz = @parXML.value('(/row/row/@idpoz)[1]', 'int')
		SET @detaliiPoz = (
				SELECT TOP 1 @parXML.query('(/row/row/detalii/row)[1]')
				)

		IF LEN(convert(VARCHAR(max), @detaliiPoz)) = 0
			SET @detaliiPoz = NULL

		IF @o_cod <> @cod
			AND EXISTS (
				SELECT *
				FROM PozDispScan ps
				WHERE ps.idPoz = @idpoz
				)
			RAISERROR ('Acest cod are linii scanate de pe terminalul mobil. Codul de produs nu poate fi modificat!', 11, 1
					)

		UPDATE PozDispOp
		SET cod = @cod, cantitate = @cantitate, pret = @pret, detalii = @detaliiPoz, utilizator = @userASiS, data_operarii = GETDATE()
		WHERE idPoz = @idpoz;
	END

	-- Trebuie chemata din nou procedura de populare pozitii pentru refresh grid
	DECLARE @xml XML;

	SET @xml = (
			SELECT @iddisp iddisp
			FOR XML raw
			);

	EXEC wIaPozDispAW @sesiune = @sesiune, @parXML = @xml;
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPozDispAW)'
END CATCH

/*******		Parte de clean up si trimitere erori		*******/
IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 11, 1)
