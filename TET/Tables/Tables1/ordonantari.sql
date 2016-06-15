CREATE TABLE [dbo].[ordonantari] (
    [Indicator]               CHAR (20)    NOT NULL,
    [Numar_ordonantare]       CHAR (8)     NOT NULL,
    [Data_ordonantare]        DATETIME     NOT NULL,
    [numar_ang_bug]           CHAR (8)     NOT NULL,
    [data_ang_bug]            DATETIME     NOT NULL,
    [numar_ang_legal]         CHAR (8)     NOT NULL,
    [data_ang_legal]          DATETIME     NOT NULL,
    [Beneficiar]              CHAR (20)    NOT NULL,
    [Contract]                CHAR (20)    NOT NULL,
    [Compartiment]            CHAR (9)     NOT NULL,
    [Suma]                    FLOAT (53)   NOT NULL,
    [Valuta]                  CHAR (3)     NOT NULL,
    [Curs]                    FLOAT (53)   NOT NULL,
    [Suma_valuta]             FLOAT (53)   NOT NULL,
    [Mod_de_plata]            CHAR (30)    NOT NULL,
    [Documente_justificative] CHAR (200)   NOT NULL,
    [Observatii]              CHAR (200)   NOT NULL,
    [Utilizator]              CHAR (10)    NOT NULL,
    [Data_operarii]           DATETIME     NOT NULL,
    [Ora_operarii]            CHAR (6)     NOT NULL,
    [Furnizor]                VARCHAR (13) DEFAULT (NULL) NULL,
    [Cont_Furnizor]           VARCHAR (35) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[ordonantari]([Indicator] ASC, [Numar_ordonantare] ASC, [Data_ordonantare] ASC);


GO
CREATE NONCLUSTERED INDEX [Pe_angajament_bugetar]
    ON [dbo].[ordonantari]([Indicator] ASC, [numar_ang_bug] ASC, [data_ang_bug] ASC);

