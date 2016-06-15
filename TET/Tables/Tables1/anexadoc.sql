CREATE TABLE [dbo].[anexadoc] (
    [Subunitate]          CHAR (9)   NOT NULL,
    [Tip]                 CHAR (2)   NOT NULL,
    [Numar]               CHAR (8)   NOT NULL,
    [Data]                DATETIME   NOT NULL,
    [Numele_delegatului]  CHAR (30)  NOT NULL,
    [Seria_buletin]       CHAR (10)  NOT NULL,
    [Numar_buletin]       CHAR (10)  NOT NULL,
    [Eliberat]            CHAR (30)  NOT NULL,
    [Mijloc_de_transport] CHAR (30)  NOT NULL,
    [Numarul_mijlocului]  CHAR (20)  NOT NULL,
    [Data_expedierii]     DATETIME   NOT NULL,
    [Ora_expedierii]      CHAR (6)   NOT NULL,
    [Observatii]          CHAR (200) NOT NULL,
    [Punct_livrare]       CHAR (5)   NOT NULL,
    [Tip_anexa]           CHAR (1)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Document]
    ON [dbo].[anexadoc]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Tip_anexa] ASC);

