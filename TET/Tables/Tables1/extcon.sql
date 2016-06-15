CREATE TABLE [dbo].[extcon] (
    [Subunitate]          CHAR (9)   NOT NULL,
    [Tip]                 CHAR (2)   NOT NULL,
    [Contract]            CHAR (20)  NOT NULL,
    [Tert]                CHAR (13)  NOT NULL,
    [Data]                DATETIME   NOT NULL,
    [Numar_pozitie]       INT        NOT NULL,
    [Precizari]           CHAR (50)  NOT NULL,
    [Clauze_speciale]     CHAR (500) NOT NULL,
    [Modificari]          CHAR (50)  NOT NULL,
    [Data_modificari]     DATETIME   NOT NULL,
    [Descriere_atasament] CHAR (50)  NOT NULL,
    [Atasament]           IMAGE      NULL,
    [Camp_1]              CHAR (50)  NOT NULL,
    [Camp_2]              CHAR (50)  NOT NULL,
    [Camp_3]              CHAR (50)  NOT NULL,
    [Camp_4]              CHAR (50)  NOT NULL,
    [Camp_5]              DATETIME   NOT NULL,
    [Utilizator]          CHAR (10)  NOT NULL,
    [Data_operarii]       DATETIME   NOT NULL,
    [Ora_operarii]        CHAR (6)   NOT NULL,
    [stare]               INT        NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[extcon]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Tert] ASC, [Data] ASC, [Numar_pozitie] ASC);

