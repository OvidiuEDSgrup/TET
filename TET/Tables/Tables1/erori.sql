CREATE TABLE [dbo].[erori] (
    [Numar_pozitie]  INT        NOT NULL,
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip_document]   CHAR (2)   NOT NULL,
    [Numar_document] CHAR (8)   NOT NULL,
    [Data_document]  DATETIME   NOT NULL,
    [Cont]           CHAR (13)  NOT NULL,
    [Tip_eroare]     CHAR (3)   NOT NULL,
    [Explicatii]     CHAR (150) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Numar_poziti]
    ON [dbo].[erori]([Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Principal]
    ON [dbo].[erori]([Subunitate] ASC, [Tip_document] ASC, [Numar_document] ASC, [Data_document] ASC);

