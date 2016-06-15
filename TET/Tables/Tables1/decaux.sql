CREATE TABLE [dbo].[decaux] (
    [Subunitate]                  CHAR (9)   NOT NULL,
    [Numar_document]              CHAR (8)   NOT NULL,
    [Data]                        DATETIME   NOT NULL,
    [L_m_furnizor]                CHAR (9)   NOT NULL,
    [Comanda_furnizor]            CHAR (13)  NOT NULL,
    [Loc_de_munca_beneficiar]     CHAR (9)   NOT NULL,
    [Comanda_beneficiar]          CHAR (13)  NOT NULL,
    [Articol_de_calculatie_benef] CHAR (9)   NOT NULL,
    [Cantitate]                   FLOAT (53) NOT NULL,
    [Valoare]                     FLOAT (53) NOT NULL,
    [Automat]                     BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[decaux]([Subunitate] ASC, [Numar_document] ASC, [Data] ASC, [L_m_furnizor] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[decaux]([Data] ASC, [Numar_document] ASC);


GO
CREATE NONCLUSTERED INDEX [Locsec]
    ON [dbo].[decaux]([Subunitate] ASC, [Data] ASC, [L_m_furnizor] ASC, [Comanda_furnizor] ASC);

