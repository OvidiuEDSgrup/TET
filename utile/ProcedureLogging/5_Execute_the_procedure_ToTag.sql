/* Just calling for debuggin purposes*/

EXEC dbo.usp_ApplyLoggingToStoredProcs @ProcedureName ='SomeProcedure', @SchemaName = NULL, @Debug = 0x1

/* Calling for execution */

EXEC dbo.usp_ApplyLoggingToStoredProcs @ProcedureName ='SomeProcedure', @SchemaName = NULL, @Debug = 0x0
