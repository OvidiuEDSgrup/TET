
CREATE trigger jurnalizare_obiecte_sql ON DATABASE	FOR
		create_procedure, alter_procedure, drop_procedure, 
		create_trigger, alter_trigger, drop_trigger,
		create_function, alter_function, drop_function,
		create_table, alter_table, drop_table
AS
BEGIN
	SET NOCOUNT ON
	SET ANSI_PADDING ON
	DECLARE 
		@data xml
	SELECT
		@data = EVENTDATA()

	INSERT INTO dbo.changelog(eventtype, objectname, objecttype, LoginName, hostname)
	SELECT
		@data.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(50)'), 
		@data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(256)'), 
		@data.value('(/EVENT_INSTANCE/ObjectType)[1]', 'varchar(25)'), 
		@data.value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(256)'),	
		HOST_NAME()
	where @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(256)') not like 'TEMP_%'
END


