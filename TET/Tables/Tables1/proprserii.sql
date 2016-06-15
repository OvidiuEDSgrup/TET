CREATE TABLE [dbo].[proprserii] (
    [Terminal]            SMALLINT  NOT NULL,
    [Numar_proprietate]   SMALLINT  NOT NULL,
    [Cod]                 CHAR (13) NOT NULL,
    [Valoare_proprietate] CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [TermNumar]
    ON [dbo].[proprserii]([Terminal] ASC, [Numar_proprietate] ASC);

