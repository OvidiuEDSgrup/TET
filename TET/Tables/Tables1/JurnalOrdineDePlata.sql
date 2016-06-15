CREATE TABLE [dbo].[JurnalOrdineDePlata] (
    [idJurnalOP] INT            IDENTITY (1, 1) NOT NULL,
    [idOP]       INT            NULL,
    [data]       DATETIME       NULL,
    [operatie]   VARCHAR (1000) NULL,
    [stare]      VARCHAR (20)   NULL,
    [utilizator] VARCHAR (100)  NULL,
    PRIMARY KEY CLUSTERED ([idJurnalOP] ASC),
    FOREIGN KEY ([idOP]) REFERENCES [dbo].[OrdineDePlata] ([idOP])
);

