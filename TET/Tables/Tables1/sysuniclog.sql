CREATE TABLE [dbo].[sysuniclog] (
    [Hostid]        CHAR (10) NOT NULL,
    [Utilizator]    CHAR (10) NOT NULL,
    [Data_intrarii] DATETIME  NOT NULL,
    [Data_iesirii]  DATETIME  NULL,
    [Aplicatia]     CHAR (6)  NOT NULL,
    [Prezenta]      DATETIME  NOT NULL
);

