CREATE TABLE [dbo].[sparg] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip_document]   CHAR (2)   NOT NULL,
    [Numar_document] CHAR (8)   NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Cont_debitor]   CHAR (13)  NOT NULL,
    [Cont_creditor]  CHAR (13)  NOT NULL,
    [Suma]           FLOAT (53) NOT NULL,
    [Valuta]         CHAR (3)   NULL,
    [Curs]           FLOAT (53) NULL,
    [Suma_valuta]    FLOAT (53) NULL,
    [Explicatii]     CHAR (50)  NOT NULL,
    [Utilizator]     CHAR (10)  NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Ora_operarii]   CHAR (6)   NOT NULL,
    [Numar_pozitie]  INT        NOT NULL,
    [Loc_de_munca]   CHAR (9)   NOT NULL,
    [Comanda]        CHAR (13)  NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[sparg]([Subunitate] ASC, [Tip_document] ASC, [Numar_document] ASC, [Data] ASC, [Cont_debitor] ASC, [Cont_creditor] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Data]
    ON [dbo].[sparg]([Subunitate] ASC, [Data] ASC);

