CREATE TABLE [dbo].[rate] (
    [Subunitate]                 CHAR (9)   NOT NULL,
    [Nr_Contract]                CHAR (20)  NOT NULL,
    [Beneficiar]                 CHAR (13)  NOT NULL,
    [Nr_ratei_curente]           SMALLINT   NOT NULL,
    [Data_scadenta_rata_curenta] DATETIME   NOT NULL,
    [Suma_rata_curenta]          FLOAT (53) NOT NULL,
    [Suma_dobanda]               FLOAT (53) NOT NULL,
    [Suma_comision_leasing]      FLOAT (53) NOT NULL,
    [Incasata]                   BIT        NOT NULL,
    [Suma_contractata_incasata]  FLOAT (53) NOT NULL,
    [Numar_document]             CHAR (8)   NOT NULL,
    [Tip_contract]               CHAR (2)   NOT NULL,
    [Suma5]                      FLOAT (53) NOT NULL,
    [Suma6]                      FLOAT (53) NOT NULL,
    [Suma7]                      FLOAT (53) NOT NULL,
    [Suma8]                      FLOAT (53) NOT NULL,
    [Suma9]                      FLOAT (53) NOT NULL,
    [Suma10]                     FLOAT (53) NOT NULL,
    [Data1]                      DATETIME   NOT NULL,
    [Data2]                      DATETIME   NOT NULL,
    [Data3]                      DATETIME   NOT NULL,
    [Alfa1]                      CHAR (200) NOT NULL,
    [Alfa2]                      CHAR (200) NOT NULL,
    [Alfa3]                      CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[rate]([Subunitate] ASC, [Tip_contract] ASC, [Nr_Contract] ASC, [Beneficiar] ASC, [Nr_ratei_curente] ASC, [Data_scadenta_rata_curenta] ASC);


GO
CREATE NONCLUSTERED INDEX [Pentru_liste]
    ON [dbo].[rate]([Subunitate] ASC, [Tip_contract] ASC, [Beneficiar] ASC, [Nr_Contract] ASC, [Nr_ratei_curente] ASC);

