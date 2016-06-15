CREATE TABLE [dbo].[ccontaiban] (
    [Cod]       CHAR (20)  NOT NULL,
    [Descriere] CHAR (200) NOT NULL,
    [Cont]      CHAR (13)  NOT NULL,
    [IBAN]      CHAR (50)  NOT NULL,
    [Banca]     CHAR (100) NOT NULL,
    [Valuta]    CHAR (3)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[ccontaiban]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Cont_contabil]
    ON [dbo].[ccontaiban]([Cont] ASC);


GO
CREATE NONCLUSTERED INDEX [IBAN]
    ON [dbo].[ccontaiban]([IBAN] ASC);

