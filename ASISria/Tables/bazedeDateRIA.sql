CREATE TABLE [dbo].[bazedeDateRIA] (
    [BD]                   VARCHAR (40)  NOT NULL,
    [nume]                 VARCHAR (250) NOT NULL,
    [connectionStringName] VARCHAR (15)  NULL,
    [poza]                 VARCHAR (30)  NULL,
    [bdActiv]              VARCHAR (50)  NULL,
    [detalii]              XML           NULL,
    CONSTRAINT [PK_bazedeDateRIA] PRIMARY KEY CLUSTERED ([BD] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Nume]
    ON [dbo].[bazedeDateRIA]([nume] ASC);

