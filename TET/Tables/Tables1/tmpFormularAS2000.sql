CREATE TABLE [dbo].[tmpFormularAS2000] (
    [utilizator] VARCHAR (40)   NOT NULL,
    [rand]       INT            NOT NULL,
    [linie]      VARCHAR (1000) NULL,
    CONSTRAINT [PK_tmpFormularAs2000] PRIMARY KEY CLUSTERED ([utilizator] ASC, [rand] ASC)
);

