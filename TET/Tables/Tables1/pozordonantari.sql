CREATE TABLE [dbo].[pozordonantari] (
    [Indicator]         CHAR (20)    NOT NULL,
    [Numar_ordonantare] CHAR (8)     NOT NULL,
    [Data_ordonantare]  DATETIME     NOT NULL,
    [Numar_pozitie]     INT          NOT NULL,
    [Numar_OP]          CHAR (8)     NOT NULL,
    [Data_OP]           DATETIME     NOT NULL,
    [Suma]              FLOAT (53)   NOT NULL,
    [Valuta]            CHAR (3)     NOT NULL,
    [Curs]              FLOAT (53)   NOT NULL,
    [Suma_valuta]       FLOAT (53)   NOT NULL,
    [Explicatii]        CHAR (200)   NOT NULL,
    [Utilizator]        CHAR (10)    NOT NULL,
    [Data_operarii]     DATETIME     NOT NULL,
    [Ora_operarii]      CHAR (6)     NOT NULL,
    [Loc_de_munca]      VARCHAR (13) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[pozordonantari]([Indicator] ASC, [Numar_ordonantare] ASC, [Data_ordonantare] ASC, [Numar_pozitie] ASC);

