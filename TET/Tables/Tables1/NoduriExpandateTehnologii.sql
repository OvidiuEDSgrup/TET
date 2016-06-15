CREATE TABLE [dbo].[NoduriExpandateTehnologii] (
    [ut] VARCHAR (200) NULL,
    [id] INT           NULL
);


GO
CREATE NONCLUSTERED INDEX [PrincNoduriExpandateTehnologii]
    ON [dbo].[NoduriExpandateTehnologii]([ut] ASC);

