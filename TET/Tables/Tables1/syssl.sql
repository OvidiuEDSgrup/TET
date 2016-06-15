CREATE TABLE [dbo].[syssl] (
    [Host_id]        CHAR (10) NOT NULL,
    [Host_name]      CHAR (30) NOT NULL,
    [Aplicatia]      CHAR (30) NOT NULL,
    [Data_stergerii] DATETIME  NOT NULL,
    [Stergator]      CHAR (10) NOT NULL,
    [Nivel]          SMALLINT  NOT NULL,
    [Cod]            CHAR (9)  NOT NULL,
    [Cod_parinte]    CHAR (9)  NOT NULL,
    [Denumire]       CHAR (30) NOT NULL
) ON [SYSS];

