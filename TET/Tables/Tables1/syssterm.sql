CREATE TABLE [dbo].[syssterm] (
    [Host_id]        CHAR (10)  NOT NULL,
    [Host_name]      CHAR (30)  NOT NULL,
    [Aplicatia]      CHAR (30)  NOT NULL,
    [Data_stergerii] DATETIME   NOT NULL,
    [Stergator]      CHAR (10)  NOT NULL,
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Contract]       CHAR (20)  NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Cod]            CHAR (20)  NOT NULL,
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
) ON [SYSS];

