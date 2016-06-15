CREATE TABLE [dbo].[Bord] (
    [Subunitate]  CHAR (9)   NOT NULL,
    [Numar]       CHAR (8)   NOT NULL,
    [Banca]       CHAR (30)  NOT NULL,
    [Cont]        CHAR (13)  NOT NULL,
    [Client]      CHAR (13)  NOT NULL,
    [Data]        DATETIME   NOT NULL,
    [Procent]     REAL       NOT NULL,
    [Total]       FLOAT (53) NOT NULL,
    [Cont_doc]    CHAR (13)  NOT NULL,
    [Data_doc]    DATETIME   NOT NULL,
    [Pozitie_doc] INT        NOT NULL,
    [Numar_doc]   CHAR (10)  NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[Bord]([Subunitate] ASC, [Numar] ASC);

