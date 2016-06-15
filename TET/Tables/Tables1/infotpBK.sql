CREATE TABLE [dbo].[infotpBK] (
    [Numar_transport]  CHAR (13)  NOT NULL,
    [Data_incarcarii]  DATETIME   NOT NULL,
    [Data_descarcarii] DATETIME   NOT NULL,
    [Transportator]    CHAR (13)  NOT NULL,
    [Sofer]            CHAR (6)   NOT NULL,
    [Masina]           CHAR (10)  NOT NULL,
    [KM]               FLOAT (53) NOT NULL,
    [Tarif]            FLOAT (53) NOT NULL,
    [Numar_paleti]     FLOAT (53) NOT NULL,
    [Observatii]       CHAR (200) NOT NULL,
    [Val1]             FLOAT (53) NOT NULL,
    [Val2]             FLOAT (53) NOT NULL,
    [Alfa1]            CHAR (200) NOT NULL,
    [Alfa2]            CHAR (200) NOT NULL,
    [Data1]            DATETIME   NOT NULL,
    [Data2]            DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[infotpBK]([Numar_transport] ASC);

