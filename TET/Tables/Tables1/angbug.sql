CREATE TABLE [dbo].[angbug] (
    [Indicator]       CHAR (20)  NOT NULL,
    [Numar]           CHAR (8)   NOT NULL,
    [Data]            DATETIME   NOT NULL,
    [Stare]           CHAR (1)   NOT NULL,
    [Loc_de_munca]    CHAR (9)   NOT NULL,
    [Beneficiar]      CHAR (20)  NOT NULL,
    [Suma]            FLOAT (53) NOT NULL,
    [Valuta]          CHAR (3)   NOT NULL,
    [Curs]            FLOAT (53) NOT NULL,
    [Suma_valuta]     FLOAT (53) NOT NULL,
    [Explicatii]      CHAR (200) NOT NULL,
    [Observatii]      CHAR (200) NOT NULL,
    [Utilizator]      CHAR (10)  NOT NULL,
    [Data_operarii]   DATETIME   NOT NULL,
    [Ora_operarii]    CHAR (6)   NOT NULL,
    [Data_angajament] DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[angbug]([Indicator] ASC, [Numar] ASC, [Data] ASC);

