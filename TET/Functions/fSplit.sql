--***
CREATE FUNCTION fSplit(
	@InputString VARCHAR(max) -- Stringul care va fi impartit in functie de delimitator
  , @Delimitator VARCHAR(max) = ',' -- delimitator
) RETURNS @Rezultat TABLE (ID int identity,string VARCHAR(max))

BEGIN
	DECLARE @string VARCHAR(8000)
	WHILE CHARINDEX(@Delimitator,@InputString,0) <> 0
	BEGIN
		SELECT
			@string=RTRIM(LTRIM(SUBSTRING(@InputString,1,CHARINDEX(@Delimitator,@InputString,0)-1))),
			@InputString=RTRIM(LTRIM(SUBSTRING(@InputString,CHARINDEX(@Delimitator,@InputString,0)+LEN(@Delimitator),LEN(@InputString))))
 
		IF LEN(@string) > 0
			INSERT INTO @Rezultat SELECT @string
	END

IF LEN(@InputString) > 0
	INSERT INTO @Rezultat SELECT @InputString -- Adaugam si ultimul string
RETURN
END
