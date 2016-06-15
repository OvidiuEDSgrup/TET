CREATE TABLE [dbo].[ChangeLog] (
    [LogId]      INT           IDENTITY (1, 1) NOT NULL,
    [EventType]  VARCHAR (50)  NOT NULL,
    [ObjectName] VARCHAR (256) NOT NULL,
    [ObjectType] VARCHAR (25)  NOT NULL,
    [EventDate]  DATETIME      CONSTRAINT [DF_EventsLog_EventDate] DEFAULT (getdate()) NOT NULL,
    [LoginName]  VARCHAR (256) NOT NULL,
    [hostname]   VARCHAR (256) NULL
);

