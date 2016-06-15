--***
CREATE FUNCTION fnGetEAN
(
	@EAN VARCHAR(13)
)
RETURNS VARCHAR(14)
AS
BEGIN
	DECLARE	@Index TINYINT,
		@Multiplier TINYINT,
		@Sum TINYINT

	SELECT	@Index = LEN(@EAN),
		@Multiplier = 3,
		@Sum = 0

	WHILE @Index > 0
		SELECT	@Sum = @Sum + @Multiplier * CAST(SUBSTRING(@EAN, @Index, 1) AS TINYINT),
			@Multiplier = 4 - @Multiplier,
			@Index = @Index - 1

	RETURN	CASE @Sum % 10
			WHEN 0 THEN @EAN + '0'
			ELSE @EAN + CAST(10 - @Sum % 10 AS CHAR(1))
		END
END
