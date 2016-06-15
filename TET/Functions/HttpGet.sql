CREATE FUNCTION [dbo].[HttpGet]
(@sURL NVARCHAR (4000))
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [HTTPGet_1].[UserDefinedFunctions].[HttpGet]


GO
EXECUTE sp_addextendedproperty @name = N'SqlAssemblyFile', @value = N'HttpGet.cs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'FUNCTION', @level1name = N'HttpGet';


GO
EXECUTE sp_addextendedproperty @name = N'SqlAssemblyFileLine', @value = N'12', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'FUNCTION', @level1name = N'HttpGet';

