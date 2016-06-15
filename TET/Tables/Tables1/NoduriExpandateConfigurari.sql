CREATE TABLE [dbo].[NoduriExpandateConfigurari] (
    [utilizator] VARCHAR (100) NULL,
    [aplicatie]  VARCHAR (100) NULL,
    [tab]        VARCHAR (100) NULL,
    [subtab]     VARCHAR (100) NULL
);


GO
CREATE NONCLUSTERED INDEX [NoduriExpandateConfigurari]
    ON [dbo].[NoduriExpandateConfigurari]([utilizator] ASC, [aplicatie] ASC, [tab] ASC, [subtab] ASC);

