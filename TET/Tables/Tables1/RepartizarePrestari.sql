CREATE TABLE [dbo].[RepartizarePrestari] (
    [idPozDoc]      INT        NULL,
    [idPozPrestare] INT        NULL,
    [suma]          FLOAT (53) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [pPrestari]
    ON [dbo].[RepartizarePrestari]([idPozPrestare] ASC, [idPozDoc] ASC);

