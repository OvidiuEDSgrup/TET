CREATE TABLE [dbo].[tmpcorelatiiMF] (
    [Subunitate]       CHAR (9)   NOT NULL,
    [Felul_operatiei]  CHAR (1)   NOT NULL,
    [Data_miscarii]    DATETIME   NOT NULL,
    [Numar_document]   CHAR (13)  NOT NULL,
    [Cont]             CHAR (13)  NOT NULL,
    [Valoare_mismf]    FLOAT (53) NOT NULL,
    [Valoare_pozincon] FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [rincipal]
    ON [dbo].[tmpcorelatiiMF]([Subunitate] ASC, [Felul_operatiei] ASC, [Data_miscarii] ASC, [Numar_document] ASC, [Cont] ASC);

