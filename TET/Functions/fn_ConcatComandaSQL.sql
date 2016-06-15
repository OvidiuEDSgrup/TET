--***
CREATE FUNCTION dbo.fn_ConcatComandaSQL(@nivel int)
RETURNS VARCHAR(8000)
AS
BEGIN
	DECLARE @Output VARCHAR(8000)
	SET @Output = ''

	SELECT @Output =CASE @Output 
				WHEN '' THEN linie
				ELSE @Output + ' where nivel= '+LTRIM(STR(@nivel)) +';'+linie
				END
	FROM tmp_Updateuri
	ORDER BY pas

	RETURN @Output
END
