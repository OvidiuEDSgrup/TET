CREATE TABLE [dbo].[syssg] (
    [Host_id]                CHAR (10)    NOT NULL,
    [Host_name]              CHAR (30)    NOT NULL,
    [Aplicatia]              CHAR (30)    NOT NULL,
    [Data_stergerii]         DATETIME     NOT NULL,
    [Stergator]              CHAR (10)    NOT NULL,
    [Subunitate]             CHAR (9)     NOT NULL,
    [Tip_gestiune]           CHAR (1)     NOT NULL,
    [Cod_gestiune]           CHAR (9)     NOT NULL,
    [Denumire_gestiune]      CHAR (43)    NOT NULL,
    [Cont_contabil_specific] VARCHAR (20) NULL
) ON [SYSS];

