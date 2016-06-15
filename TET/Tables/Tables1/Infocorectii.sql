CREATE TABLE [dbo].[Infocorectii] (
    [Data]               DATETIME   NOT NULL,
    [Marca]              CHAR (6)   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Tip_corectie_venit] CHAR (2)   NOT NULL,
    [Tip_document]       CHAR (2)   NOT NULL,
    [Numar]              CHAR (8)   NOT NULL,
    [Data_doc]           DATETIME   NOT NULL,
    [Valoare_doc]        FLOAT (53) NOT NULL,
    [Suma_fixa]          FLOAT (53) NOT NULL,
    [Procent]            REAL       NOT NULL,
    [Valoare_decont]     FLOAT (53) NOT NULL,
    [Utilizator]         CHAR (10)  NOT NULL,
    [Data_operarii]      DATETIME   NOT NULL,
    [Ora_operarii]       CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Tip_numar_data]
    ON [dbo].[Infocorectii]([Data] ASC, [Marca] ASC, [Loc_de_munca] ASC, [Tip_corectie_venit] ASC, [Tip_document] ASC, [Numar] ASC, [Data_doc] ASC);

