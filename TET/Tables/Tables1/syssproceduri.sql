CREATE TABLE [dbo].[syssproceduri] (
    [EventType]         VARCHAR (MAX)  NULL,
    [ObjectName]        VARCHAR (MAX)  NULL,
    [ObjectType]        VARCHAR (MAX)  NULL,
    [tsql]              NVARCHAR (MAX) NULL,
    [Session_IPAddress] VARCHAR (MAX)  NULL,
    [utilizator]        VARCHAR (MAX)  NULL,
    [data_modificarii]  DATETIME       NULL
) ON [SYSS] TEXTIMAGE_ON [SYSS];

