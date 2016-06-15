CREATE TABLE [dbo].[termene_coduri_mari] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Contract]       CHAR (20)  NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Cod]            CHAR (30)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Termen]         DATETIME   NOT NULL,
    [Cantitate]      FLOAT (53) NOT NULL,
    [Cant_realizata] FLOAT (53) NOT NULL,
    [Pret]           FLOAT (53) NOT NULL,
    [Explicatii]     CHAR (200) NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Data1]          DATETIME   NOT NULL,
    [Data2]          DATETIME   NOT NULL
);

