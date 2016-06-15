
CREATE PROCEDURE wOPPopulareLocatii @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @Gestiune VARCHAR(9), @capacitate INT, @Rand INT, @coloana INT, @um VARCHAR(3), @Raft VARCHAR(10)

SET @Gestiune = @parXML.value('(/*/@gestiune)[1]', 'varchar(9)')
SET @capacitate = @parXML.value('(/*/@capacitate)[1]', 'int')
SET @um = @parXML.value('(/*/@um)[1]', 'varchar(3)')
SET @Raft = @parXML.value('(/*/@raft)[1]', 'varchar(10)')
SET @coloana = @parXML.value('(/*/@coloana)[1]', 'int')
SET @Rand = @parXML.value('(/*/@rand)[1]', 'int')

IF isnull(@Gestiune, '') = ''
	OR isnull(@capacitate, 0) = 0
	OR ISNULL(@um, '') = ''
	OR ISNULL(@raft, '') = ''
	OR isnull(@coloana, 0) = 0
	OR isnull(@rand, 0) = 0
	
BEGIN
	RAISERROR ('Toate campurile sunt obligatorii!', 11, 1)

	RETURN - 1
END
ELSE
BEGIN
	DECLARE @i INT, @j INT, @lmax INT, @k INT

	SET @lmax = 3

	DECLARE @randcalc VARCHAR(10), @colcalc VARCHAR(10)

	DELETE
	FROM locatii
	WHERE cod_gestiune = @gestiune
		AND cod_locatie LIKE rtrim(@Raft) + '%'

	SET @i = 0

	WHILE @i <= @coloana
	BEGIN
		SET @colcalc = ltrim(str(@i))
		SET @k = len(@colcalc)

		IF @i = 0
		BEGIN
			SET @colcalc = ''
		END
		ELSE
		BEGIN
			SET @k = len(@colcalc)

			WHILE @k < @lmax
			BEGIN
				SET @colcalc = '0' + @colcalc
				SET @k = @k + 1
			END

			SET @colcalc = '.' + @colcalc
		END

		SET @j = 0

		WHILE @j <= @Rand
		BEGIN
			SET @randcalc = ltrim(str(@j))

			IF @j = 0
			BEGIN
				SET @randcalc = ''
			END
			ELSE
			BEGIN
				SET @k = len(@randcalc)

				WHILE @k < @lmax
				BEGIN
					SET @randcalc = '0' + @randcalc
					SET @k = @k + 1
				END

				SET @randcalc = '.' + @randcalc
			END

			INSERT INTO locatii
			VALUES (
				rtrim(@Raft) + @colcalc + @randcalc, (
					CASE WHEN @i = 0
							OR @j = 0 THEN 1 ELSE 0 END
					), (
					CASE WHEN @i = 0
							AND @j = 0 THEN '' WHEN @j = 0 THEN rtrim(@Raft) ELSE rtrim(@Raft) + @colcalc END
					), @um, @capacitate, @Gestiune, 0, (
					CASE WHEN @i = 0
							AND @j = 0 THEN 1 WHEN @j = 0 THEN 2 ELSE 3 END
					), (
					CASE WHEN @i = 0
							AND @j = 0 THEN 'Raftul:' + rtrim(@Raft) WHEN @j = 0 THEN 'Raftul:' + rtrim(@Raft) + ',Coloana:' + ltrim(str(@i
									)) ELSE 'Raftul:' + rtrim(@Raft) + ',Coloana:' + ltrim(str(@i)) + ',Randul:' + ltrim(str(@j)) END
					)
				)

			IF @i = 0
				SET @j = @Rand + 1
			ELSE
				SET @j = @j + 1
		END

		SET @i = @i + 1
	END
END
