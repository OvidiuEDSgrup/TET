CREATE TABLE [dbo].[ContrSoc] (
    [Cod_contributie]   CHAR (20)  NOT NULL,
    [Cod_declaratie]    CHAR (20)  NOT NULL,
    [Punct_de_lucru]    CHAR (13)  NOT NULL,
    [Data]              DATETIME   NOT NULL,
    [Cod_bugetar]       CHAR (20)  NOT NULL,
    [Nr_evidenta_plati] CHAR (40)  NOT NULL,
    [Suma_datorata]     FLOAT (53) NULL,
    [Deductibila]       FLOAT (53) NULL,
    [Suma_de_plata]     FLOAT (53) NOT NULL,
    [Suma_de_recuperat] FLOAT (53) NOT NULL,
    [Explicatii]        CHAR (200) NOT NULL,
    [Notatie]           CHAR (100) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_si_data]
    ON [dbo].[ContrSoc]([Cod_contributie] ASC, [Cod_declaratie] ASC, [Punct_de_lucru] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Dupa_data]
    ON [dbo].[ContrSoc]([Data] ASC);

