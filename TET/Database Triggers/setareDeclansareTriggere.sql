CREATE TRIGGER setareDeclansareTriggere
on database 
FOR CREATE_TRIGGER,ALTER_TRIGGER
as

IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'tr_validPozdoc') AND type='TR')
 exec sp_settriggerorder	@triggername = 'tr_validPozdoc', 
							@order = 'LAST', 
							@stmttype = 'INSERT',
							@namespace = NULL 
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'tr_validPozincon') AND type='TR')
exec sp_settriggerorder	@triggername = 'tr_validPozincon', 
							@order = 'LAST', 
							@stmttype = 'INSERT',
							@namespace = NULL 


