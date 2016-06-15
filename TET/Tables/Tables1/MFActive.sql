CREATE TABLE [dbo].[MFActive] (
    [Subunitate]        CHAR (9)   NOT NULL,
    [Cod_activ]         CHAR (20)  NOT NULL,
    [Numar_de_inventar] CHAR (13)  NOT NULL,
    [suprafata_totala]  FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[MFActive]([Subunitate] ASC, [Cod_activ] ASC, [Numar_de_inventar] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Numar_de_inventar]
    ON [dbo].[MFActive]([Subunitate] ASC, [Numar_de_inventar] ASC);

