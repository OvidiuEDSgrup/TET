CREATE TABLE [dbo].[registrucfp] (
    [Tip]           CHAR (1)   NOT NULL,
    [Indicator]     CHAR (20)  NOT NULL,
    [Numar]         CHAR (8)   NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Numar_pozitie] INT        NOT NULL,
    [Numar_CFP]     CHAR (20)  NOT NULL,
    [Data_CFP]      DATETIME   NOT NULL,
    [Observatii]    CHAR (200) NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[registrucfp]([Tip] ASC, [Indicator] ASC, [Numar] ASC, [Data] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar_CFP]
    ON [dbo].[registrucfp]([Numar_CFP] ASC);

