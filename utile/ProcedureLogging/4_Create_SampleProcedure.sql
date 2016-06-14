
/*
	This sample is just for testing the logging tagging
*/

CREATE Procedure dbo.SomeProcedure
(
	@MyParameter VARCHAR(MAX),
	@MySecondParameter INT
)
AS
SELECT @MyParameter,@MySecondParameter


