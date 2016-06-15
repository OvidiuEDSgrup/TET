

create  TRIGGER [trgLogDDLEvent] ON DATABASE 
    FOR DDL_DATABASE_LEVEL_EVENTS 
AS 
	SET NOCOUNT ON
	SET ANSI_PADDING ON
	SET ANSI_NULLS ON
	SET QUOTED_IDENTIFIER ON

    DECLARE @data XML 
    SET @data = EVENTDATA() 
    IF @data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)') 
        <> 'CREATE_STATISTICS' AND  @data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)')
        <>  'UPDATE_STATISTICS' 
        BEGIN 
        INSERT  INTO syssproceduri 
                ( 
                  EventType, 
                  ObjectName, 
                  ObjectType, 
                  tsql ,
                  Session_IPAddress,
                          utilizator,
                          data_modificarii
                ) 
                SELECT @data.value('(/EVENT_INSTANCE/EventType)[1]', 
                              'nvarchar(100)'), 
                  @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 
                              'nvarchar(100)'), 
                  @data.value('(/EVENT_INSTANCE/ObjectType)[1]', 
                              'nvarchar(100)'), 
                  @data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 
                              'nvarchar(max)'), client_net_address,
                        SUSER_NAME(),
                        getdate()
                 FROM sys.dm_exec_connections WHERE session_id=@@SPID
          END


