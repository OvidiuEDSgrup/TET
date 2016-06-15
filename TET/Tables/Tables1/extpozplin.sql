CREATE TABLE [dbo].[extpozplin] (
    [Subunitate]         CHAR (9)   NOT NULL,
    [Cont]               CHAR (13)  NOT NULL,
    [Data]               DATETIME   NOT NULL,
    [Numar]              CHAR (10)  NOT NULL,
    [Numar_pozitie]      INT        NOT NULL,
    [Tip]                CHAR (2)   NOT NULL,
    [Cont_corespondent]  CHAR (13)  NOT NULL,
    [Marca]              CHAR (13)  NOT NULL,
    [Decont]             CHAR (13)  NOT NULL,
    [Data_scadentei]     DATETIME   NOT NULL,
    [Suma]               FLOAT (53) NOT NULL,
    [Suma_achitat]       FLOAT (53) NOT NULL,
    [Banca]              CHAR (20)  NOT NULL,
    [Cont_in_banca]      CHAR (35)  NOT NULL,
    [Numar_justificare]  CHAR (8)   NOT NULL,
    [Data_document]      DATETIME   NOT NULL,
    [Serie_CEC]          CHAR (20)  NOT NULL,
    [Numar_CEC]          CHAR (20)  NOT NULL,
    [Banca_tert]         CHAR (20)  NOT NULL,
    [Cont_in_banca_tert] CHAR (35)  NOT NULL,
    [Jurnal]             CHAR (3)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ExtPozplin]
    ON [dbo].[extpozplin]([Subunitate] ASC, [Cont] ASC, [Data] ASC, [Numar_pozitie] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Decont]
    ON [dbo].[extpozplin]([Subunitate] ASC, [Marca] ASC, [Decont] ASC);

