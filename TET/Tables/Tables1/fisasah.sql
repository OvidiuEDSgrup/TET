CREATE TABLE [dbo].[fisasah] (
    [Subunitate]       CHAR (9)   NOT NULL,
    [Numar_ordine]     INT        NOT NULL,
    [Cont]             CHAR (20)  NOT NULL,
    [Data]             DATETIME   NOT NULL,
    [Tip_doc_debit]    CHAR (2)   NOT NULL,
    [Numar_doc_debit]  CHAR (8)   NOT NULL,
    [Data_debit]       DATETIME   NOT NULL,
    [Cont_creditare]   CHAR (20)  NOT NULL,
    [Suma_debit]       FLOAT (53) NOT NULL,
    [Tip_doc_credit]   CHAR (2)   NOT NULL,
    [Numar_doc_credit] CHAR (8)   NOT NULL,
    [Data_credit]      DATETIME   NOT NULL,
    [Cont_debitare]    CHAR (20)  NOT NULL,
    [Suma_credit]      FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Fisa_sah_Unic]
    ON [dbo].[fisasah]([Subunitate] ASC, [Cont] ASC, [Numar_ordine] ASC);


GO
CREATE NONCLUSTERED INDEX [Fisa_sah_DEBIT]
    ON [dbo].[fisasah]([Subunitate] ASC, [Cont] ASC, [Cont_creditare] ASC, [Cont_debitare] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Fisa_sah_CREDIT]
    ON [dbo].[fisasah]([Subunitate] ASC, [Cont] ASC, [Cont_debitare] ASC, [Cont_creditare] ASC, [Data] ASC);

