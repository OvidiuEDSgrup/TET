
CREATE PROCEDURE GenerareAntecalculatii @sesiune VARCHAR(50), @parXML XML
AS
DECLARE 
	@nRanduri INT, @calculat INT, @id INT, @cod VARCHAR(20), @grupa VARCHAR(20), @utilizator VARCHAR(100), @mesaj VARCHAR(500)

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @id = @parXML.value('(/row/@id)[1]', 'int')

	/* Daca @id nu este null inseamna ca e doar o modificare
	Se va calcula in cazul modificarii doar componenta de materiale, manopera si recapitulatie 
	fara a se tine seama de semifabricatele din structura proprie
*/

	IF NOT EXISTS (SELECT 1	FROM par WHERE tip_parametru = 'MP' AND Parametru = 'INCLCAC')
		INSERT INTO par (Tip_parametru, Parametru, Denumire_parametru, Val_logica, Val_numerica, Val_alfanumerica)
		VALUES ('MP', 'INCLCAC', 'In calcul antecalculatie', 1, 0, '')

	IF EXISTS (SELECT *	FROM sysobjects	WHERE NAME = 'anteclcpecoduri')
	BEGIN
		IF (SELECT TOP 1 val_logica	FROM par WHERE Tip_parametru = 'MP'	AND Parametru = 'INCLCAC') = 0
			DROP TABLE anteclcpeCoduri
		ELSE
		BEGIN
			UPDATE par
				SET Val_logica = 0
			WHERE Tip_parametru = 'MP' AND Parametru = 'INCLCAC'

			RAISERROR ('Eroare! Operatia este rulata de catre altcineva. Reveniti in cateva minute!', 16, 1)
		END
	END

	UPDATE par
		SET Val_logica = 1
	WHERE Tip_parametru = 'MP' AND Parametru = 'INCLCAC'

	CREATE TABLE anteclcpeCoduri (cod VARCHAR(20), nivel INT, rezolvat INT, Mat DECIMAL(12, 5), Man DECIMAL(12, 5), TP DECIMAL(12, 5))

	IF @id IS NULL --Facem bucla cu semifabricate
	BEGIN
		SET @cod = @parXML.value('(/row/@cod)[1]', 'varchar(20)')
		SET @grupa = @parXML.value('(/row/@grupa)[1]', 'varchar(20)')
		SET @id = @parXML.value('(/row/@id)[1]', 'int')

		DELETE FROM tmpprodsisemif WHERE utilizator = @utilizator

		INSERT INTO tmpprodsisemif (id, utilizator, tip, codNomencl, idp, codp, nivel, cantitate)
		SELECT 
			MIN(pt.id), @utilizator, (CASE WHEN MIN(LEFT(n.Cont, 3)) = '345' THEN 'P' ELSE 'S' END), t.cod,NULL, NULL, 0, 1
		FROM dbo.tehnologii t
		INNER JOIN nomencl n ON n.cod = t.codNomencl
		INNER JOIN dbo.pozTehnologii pt ON pt.tip = 'T'	AND pt.cod = t.cod
		WHERE 
			(@cod IS NULL OR t.cod = @cod) AND 
			(@grupa IS NULL	OR n.Grupa = @grupa) AND 
			(@cod IS NULL AND @grupa IS NULL OR n.tip in ('P','S'))
		GROUP BY t.cod

		EXEC FaSemifabricateDinProduse @sesiune, @parXML OUTPUT

		/* Adaugam elementele din antecalculatii*/
		INSERT INTO anteclcpeCoduri (cod, nivel, rezolvat, Mat, Man)
		SELECT codNomencl, MAX(nivel) AS nivel, 0 AS rezolvat, 0.00, 0.00
		FROM tmpprodsisemif
		WHERE utilizator = @utilizator
		GROUP BY codNomencl

	END --Gata bucla cu semifabricate
	ELSE
	BEGIN -- Pentru modificare => avem @id de antecalculatie
		SET @parXML.modify('insert attribute nivel{1} into (/row)[1]')

		--Stergem antecalculatia pentru acel @id
		DECLARE @idTop INT

		SELECT @idTop = idPoz
		FROM dbo.Antecalculatii
		WHERE idAntec = @id

		IF OBJECT_ID('tempdb..##ElemSterse') IS NOT NULL
			DROP TABLE ##ElemSterse
		create table ##ElemSterse (cod varchar(20), cantitate float) 		
		
		DELETE
		FROM dbo.pozAntecalculatii
		OUTPUT deleted.cod, deleted.cantitate
		INTO ##ElemSterse (cod, cantitate)
		WHERE parinteTop = @idTop
			AND tip = 'E'

		INSERT INTO anteclcpeCoduri (cod, nivel, rezolvat, Mat, Man, TP)
		SELECT n.cod, 1 AS nivel, 0 AS rezolvat, 0.00, 0.00, 0.00
		FROM dbo.Antecalculatii ac
		INNER JOIN tehnologii n ON ac.Cod = n.Cod
		WHERE ac.idAntec = @id
	END

	EXEC CalculRecapitulatie @sesiune = @sesiune, @parXML = @parXML
	EXEC ScrieAntecalculatiaDinAnteclcPeCoduri @sesiune, @parXML

	UPDATE par
	SET Val_logica = 0
	WHERE Tip_parametru = 'MP' AND Parametru = 'INCLCAC'

	DROP TABLE anteclcpeCoduri
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (GenerareAntecalculatii)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
