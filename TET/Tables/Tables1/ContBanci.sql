CREATE TABLE [dbo].[ContBanci] (
    [Subunitate]    CHAR (9)  NOT NULL,
    [Tert]          CHAR (13) NOT NULL,
    [Numar_pozitie] INT       NOT NULL,
    [Banca]         CHAR (20) NOT NULL,
    [Cont_in_banca] CHAR (35) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Banca_pe_tert]
    ON [dbo].[ContBanci]([Subunitate] ASC, [Tert] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Nume_banca]
    ON [dbo].[ContBanci]([Banca] ASC);

