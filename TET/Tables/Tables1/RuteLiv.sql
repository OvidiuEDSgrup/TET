CREATE TABLE [dbo].[RuteLiv] (
    [Cod]                CHAR (20) NOT NULL,
    [Denumire]           CHAR (30) NOT NULL,
    [Schimb]             SMALLINT  NOT NULL,
    [Delegat]            CHAR (30) NOT NULL,
    [numarul_mijlocului] CHAR (10) NOT NULL,
    [Serie_buletin]      CHAR (2)  NOT NULL,
    [Numar_Buletin]      CHAR (6)  NOT NULL,
    [Eliberat]           CHAR (15) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[RuteLiv]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Delegat_si_miljoc_de_transport]
    ON [dbo].[RuteLiv]([Delegat] ASC, [numarul_mijlocului] ASC);

