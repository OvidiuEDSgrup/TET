DECLARE @HashThis nvarchar(4000);
SELECT @HashThis = CONVERT(nvarchar(4000),'1234567890123');
SELECT convert(varchar,HashBytes('MD5', @HashThis))
GO
