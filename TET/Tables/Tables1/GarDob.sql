CREATE TABLE [dbo].[GarDob] (
    [Data_lunii_curente] DATETIME   NOT NULL,
    [Marca]              CHAR (6)   NOT NULL,
    [Tert]               CHAR (13)  NOT NULL,
    [Banca]              CHAR (30)  NOT NULL,
    [Tip_operatie]       CHAR (1)   NOT NULL,
    [Data]               DATETIME   NOT NULL,
    [Cont]               CHAR (13)  NOT NULL,
    [Valoare]            FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[GarDob]([Data_lunii_curente] ASC, [Marca] ASC, [Tert] ASC, [Banca] ASC, [Data] ASC, [Tip_operatie] ASC);

