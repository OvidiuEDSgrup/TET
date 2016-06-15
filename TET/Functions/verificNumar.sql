-- =============================================
-- Author:		yso
-- Create date: 
-- Description:	
-- =============================================
CREATE FUNCTION [yso].[verificNumar] 
(
	-- Add the parameters for the function here
	@nrAlfa varchar(200)
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @nrNumeric int

	-- Add the T-SQL statements to compute the return value here
	SELECT @nrNumeric = CASE ISNUMERIC(REPLACE(ISNULL(@nrAlfa,''),',','')) WHEN 1 THEN CONVERT(INT,REPLACE(@nrAlfa,',','')) ELSE NULL END

	-- Return the result of the function
	RETURN @nrNumeric

END
