
CREATE PROCEDURE [dbo].[wScriuElementeAntec] @sesiune VARCHAR(50), @parXML XML
AS
begin try
	DECLARE @cod VARCHAR(20), @descriere VARCHAR(80), @formula VARCHAR(1000), @procent BIT, @valoare FLOAT, @parinte VARCHAR(20), @update 
		BIT, @pas INT, @cvaloare VARCHAR(20), @mesaj varchar(max)

	--Date element
	SET @cod = ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), '')
	SET @descriere = ISNULL(@parXML.value('(/row/@descriere)[1]', 'varchar(20)'), '')
	SET @parinte = ISNULL(@parXML.value('(/row/@parinte)[1]', 'varchar(20)'), '')
	SET @formula = ISNULL(@parXML.value('(/row/@n_formula)[1]', 'varchar(1000)'), '')
	SET @procent = ISNULL(@parXML.value('(/row/@n_procent)[1]', 'bit'), 0)
	SET @pas = (
			CASE WHEN ISNUMERIC(@parXML.value('(/row/@pas)[1]', 'varchar(20)')) = 1 THEN @parXML.value('(/row/@pas)[1]', 'int') ELSE 0 
				END
			)
	SET @cvaloare = ISNULL(@parXML.value('(/row/@valoare)[1]', 'varchar(20)'), '')
	SET @cvaloare = replace(@cvaloare, '%', '')
	SET @cvaloare = replace(@cvaloare, '-', '')

	IF isnumeric(@cvaloare) = 1
		SET @valoare = CONVERT(DECIMAL(12, 2), @cvaloare)
	ELSE
		SET @valoare = 0

	--Alte
	SET @update = ISNULL(@parXML.value('(/row/@update)[1]', 'bit'), 0)

	--validari	
	IF @update = 0
	BEGIN
		IF (
				SELECT COUNT(*)
				FROM elemantec
				WHERE element = @cod
				) > 0
			OR (
				SELECT COUNT(*)
				FROM elemantec
				WHERE descriere = @descriere
				) > 0
		BEGIN
			RAISERROR ('Cod sau descriere asociate deja altui element!', 11, 1)
		END

		IF @parinte = '-'
			SET @parinte = NULL

		IF @procent = 0
			SET @valoare = NULL

		INSERT INTO elemantec (Element, Descriere, Articol_de_calculatie, Formula, NrOrdine, procent, element_parinte, valoare_implicita, pas
			)
		VALUES (
			@cod, @descriere, '', @formula, isnull((
					SELECT MAX(nrOrdine) + 1
					FROM elemantec
					), 1), @procent, @parinte, @valoare, @pas
			)
	END
	ELSE
		IF @update = 1
		BEGIN
			DECLARE @o_cod VARCHAR(20)

			SET @o_cod = ISNULL(@parXML.value('(/row/@o_cod)[1]', 'varchar(20)'), '')

			IF @o_cod != @cod
			BEGIN
				SET @cod = @o_cod

				RAISERROR ('Nu este permisa modificarea codului. Restul modificarilor s-au salvat!', 11, 1
						)
			END

			UPDATE elemantec
			SET Formula = @formula, element_parinte = @parinte, Descriere = @descriere, valoare_implicita = @valoare / 100, pas = @pas, 
				procent = @procent
			WHERE element = @cod
		END
end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wScriuElementeAntec)'
	raiserror(@mesaj, 11, 1)
end catch
