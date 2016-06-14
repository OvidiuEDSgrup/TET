-- ================================================
-- Template generated from Template Explorer using:
-- Create Scalar Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		yso
-- Create date: 
-- Description:	
-- =============================================
ALTER FUNCTION yso.verificNumar 
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
GO

