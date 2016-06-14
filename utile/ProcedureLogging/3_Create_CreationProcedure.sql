/*
	This bascially contains the change script whereas the part for logging is placed
	after the AS starting point in the stored procedure.
	Written by Jens Suessmeyer (Jenss) (20.04.2009) in communication with Claes Norell (clnorell)
	The code within this solution is for testing purposes only and has no gurantee to run on every system under
	every circumstance, thourough testing of the code is recommended
*/


CREATE PROCEDURE dbo.usp_ApplyLoggingToStoredProcs
(
	--Passing in NULL for ProcedureName will do all procedures of a schema (if specified)
	@ProcedureName SYSNAME = NULL,
	--Passing in a schema name will do all procedures in that schema 
	--(if no procedure name is specified) 
	@SchemaName SYSNAME = NULL,
	@Debug BIT = 0 --If set to 1 no actions will be done, only the schange scripts generated and brought to the output
)
AS

BEGIN

SET NOCOUNT ON

/* Variable declaration*/
DECLARE @ROWCOUNTER SMALLINT

DECLARE @ProcCommandText VARCHAR(MAX)
DECLARE @ChoppedProcCommandText VARCHAR(MAX)
DECLARE @Firstpart VARCHAR(MAX)
DECLARE @SecondPart VARCHAR(MAX)
--Delimites parameters passed to the logging procedure
DECLARE @Delimiter VARCHAR(10)
DECLARE @LoggingCommand VARCHAR(MAX)
DECLARE @ParameterNameList VARCHAR(MAX)
DECLARE @ParameterValueList VARCHAR(MAX)
DECLARE @CurrentStoredProcedure SYSNAME
DECLARE @CurrentSchema SYSNAME

/* Variable declaration*/


/*Working table holding the information of the procedures to be tagged*/
CREATE TABLE #WorkingTable
(
	CounterId SMALLINT IDENTITY(1,1),
	SchemaName SYSNAME,
	ProcedureName SYSNAME
)

/*Get all the procedures that have to be tagged and put them in the working table*/

INSERT INTO #WorkingTable
	(SchemaName,ProcedureName)
SELECT 
	ROUTINE_SCHEMA,
	ROUTINE_NAME	
FROM INFORMATION_SCHEMA.ROUTINES
WHERE 
	ROUTINE_NAME	= ISNULL(@ProcedureName, ROUTINE_NAME) AND
	ROUTINE_SCHEMA	= ISNULL(@SchemaName, ROUTINE_SCHEMA)
AND ROUTINE_NAME != OBJECT_NAME(@@PROCID) AND ROUTINE_NAME != 'usp_LogParameters'
ORDER BY ROUTINE_NAME DESC

SET @ROWCOUNTER = @@ROWCOUNT


/* Now iterate through the procs and tag them*/
WHILE @ROWCOUNTER > 0
BEGIN

/*Initialization*/
	SET @Firstpart = ''
	SET @SecondPart = ''
	SET @Delimiter = '|'
	SET @LoggingCommand = ''
	SET @ProcCommandText = ''
	SET @SecondPart = ''
	SET @ParameterNameList = ''
	SET @CurrentSchema = ''
	SET @CurrentStoredProcedure = ''
	SET @ParameterValueList = ''
/*End of Initialization*/


SELECT 
	@CurrentSchema = SchemaName,
	@CurrentStoredProcedure = ProcedureName
FROM #WorkingTable
WHERE CounterId = @ROWCOUNTER

	SELECT 
		@ParameterNameList = @ParameterNameList + PARAMETER_NAME + @Delimiter,
		@ParameterValueList = @ParameterValueList + 'CAST(' + PARAMETER_NAME + ' AS VARCHAR(MAX)) +' + QUOTENAME(@Delimiter,CHAR(39)) + '+'
	FROM INFORMATION_SCHEMA.PARAMETERS p
	WHERE 
		p.SPECIFIC_NAME = @CurrentStoredProcedure AND 
		p.SPECIFIC_SCHEMA = @CurrentSchema
		
	SELECT 
		@LoggingCommand =	'/*Begin parameter logging*/' + CHAR(13) + 
					'	DECLARE @Logging_Parameters VARCHAR(MAX)' + CHAR(13) + 
					'	DECLARE @Logging_Values VARCHAR(MAX)' + CHAR(13) +
					'	DECLARE @Logging_DatabaseName SYSNAME' + CHAR(13) +
					'	DECLARE @Logging_ProcedureSchema SYSNAME' + CHAR(13) +
					'	DECLARE @Logging_ProcedureName SYSNAME' + CHAR(13) +
					'	SELECT' + CHAR(13) + 
					'		@Logging_DatabaseName = SPECIFIC_CATALOG,' + CHAR(13) +
					'		@Logging_ProcedureSchema = SPECIFIC_SCHEMA,' + CHAR(13) +
					'		@Logging_ProcedureName = SPECIFIC_NAME' + CHAR(13) +
					'	FROM INFORMATION_SCHEMA.ROUTINES' + CHAR(13) +
					'	WHERE OBJECT_ID(ROUTINE_SCHEMA + ''.'' + ROUTINE_NAME) = @@PROCID' + CHAR(13) +
					'	SET @Logging_Parameters = ' + QUOTENAME(LEFT(@ParameterNameList, LEN(@ParameterNameList)-LEN(@Delimiter)), CHAR(39)) + CHAR(13) + 
					'	SET @Logging_Values = ' + LEFT(@ParameterValueList, LEN(@ParameterValueList)- (4+ LEN(@Delimiter))) + CHAR(13) + 
					'		EXEC usp_LogParameters @DatabaseName = Logging_DatabaseName, @ProcedureName = @Logging_ProcedureName, @ProcedureSchema = @Logging_ProcedureSchema, @LoggingParameters = @Logging_Parameters, @LoggingValues = @Logging_Values' + CHAR(13) + 
					'/*Endof parameter logging*/' + CHAR(13)


	/* 
		First create an ALTER statement instead of a create which is present in the metadata
		Therefore the actual current create statement has to be found and replaced by the ALTER statement
	*/
	
	
	SELECT @ProcCommandText = 
		LEFT(Routine_DEFINITION,PATINDEX('%CREATE%PROCEDURE%',ROUTINE_DEFINITION)-1) + 
		'ALTER' +
		RIGHT(ROUTINE_DEFINITION, LEN(ROUTINE_DEFINITION) - PATINDEX('%CREATE%PROCEDURE%',ROUTINE_DEFINITION) - 5 /* 5 for the CREATE*/)
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE 
		ROUTINE_NAME = @CurrentStoredProcedure AND 
		ROUTINE_SCHEMA = @CurrentSchema
		
		
	/*Check for existing logging*/


	IF CHARINDEX('/*Begin parameter logging*/', @ProcCommandText) > 0
		SELECT @ChoppedProcCommandText = 
			LEFT(@ProcCommandText, CHARINDEX('/*Begin parameter logging*/',@ProcCommandText)-1) +
			RIGHT(@ProcCommandText, LEN(@ProcCommandText) - CHARINDEX('/*Endof parameter logging*/',@ProcCommandText)- LEN('/*Endof parameter logging*/'))
	ELSE
		SET @ChoppedProcCommandText = @ProcCommandText
	
	
	/* Split the procedure in the header (Part before the AS, including the AS) and the part after
	   the AS (excluding the AS)
	*/
	SELECT 
		@Firstpart = LEFT(@ChoppedProcCommandText,CHARINDEX('AS' + CHAR(13),@ChoppedProcCommandText)+2),
		@Secondpart = RIGHT(@ChoppedProcCommandText,LEN(@ChoppedProcCommandText) - CHARINDEX('AS' + CHAR(13),@ChoppedProcCommandText)-2)

	/*
		Compose the whole query
	*/


	SELECT @ChoppedProcCommandText = @Firstpart + @LoggingCommand + @Secondpart
	
	/*Debugging*/
	IF @Debug = 1
		PRINT @ChoppedProcCommandText
	ELSE
		EXEC(@ChoppedProcCommandText)
		
SET @ROWCOUNTER = @ROWCOUNTER - 1
END --Of While

END --Of Proc

RETURN 

GO