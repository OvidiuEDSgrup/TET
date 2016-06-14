drop PROCEDURE [dbo].[CleanDataFromAlpha]
go
CREATE PROCEDURE [dbo].[CleanDataFromAlpha]
@alpha VARCHAR(20),
@decimal DECIMAL(14, 5) OUTPUT
AS BEGIN
SET NOCOUNT ON;
DECLARE @ErrorMsg VARCHAR(50)
DECLARE @Pos INT
DECLARE @CommaPos INT
DECLARE @ZeroExists INT
DECLARE @alphaReverse VARCHAR(50)
DECLARE @NumPos INT
DECLARE @Len INT
-- 1 Reverse the alpha in order to get the last position of a numeric value
SET @alphaReverse = REVERSE(@alpha)
-- 2 Get the last position of a numeric figure
SET @NumPos = PATINDEX('%[0-9]%', @alphaReverse)
-- 3 Get the lenght of the string
SET @Len = LEN(@alpha)
-- 4 Add a comma after the numeric data in case it's no decimal number
SET @alpha = SUBSTRING(@alpha, 1, (@Len - @NumPos + 1))
+ ','
+ SUBSTRING(@alpha, (@Len - @NumPos + 2), 50)
-- Check if there is a zero (0) in the @alpha, then we later set the @decimal to 0
-- if it's 0 after the handling, else we set @decimal to NULL
-- If 0 no match, else there is a match
SET @ZeroExists = CHARINDEX ( '0' , @alpha ,1 )
-- Find position of , (comma)
SET @CommaPos = 1
SET @CommaPos = PATINDEX('%,%', @alpha)
IF (@CommaPos = '') BEGIN
SET @CommaPos = 20
END
SET @Pos = PATINDEX('%[^0-9]%',@alpha)
-- Replaces any aplha with '0' since we otherwice can't keep track of where the decimal
-- should be put in. We assume the numeric number has no aplhe inside. The regular way
-- to solve this is to replace with ”, but then we miss the way to find the place to
-- put in the decimal.
WHILE (@Pos > 0) BEGIN
SET @alpha = STUFF(@alpha, @pos, 1, '0')
SET @Pos = PATINDEX('%[^0-9]%',@alpha)
END
IF (@alpha IS NOT NULL AND @alpha != '') BEGIN
SET @decimal = CONVERT(DECIMAL(14, 5), SUBSTRING(@alpha, 1, (@CommaPos - 1))
+ '.'
+ SUBSTRING(@alpha, (@CommaPos + 1), 20))
END
-- Since we in this case don't want to set 0 if where is no numeric value, we set NULL to be safe
IF (@decimal = 0 AND @ZeroExists = 0) BEGIN
SET @decimal = NULL
END
END
GO

--If you run above SP as shown below it will work
DECLARE @myRetVal DECIMAL(14,5)
EXEC [CleanDataFromAlpha] '1/03    ', @myRetVal OUTPUT
SELECT @myRetVal ReturnValue