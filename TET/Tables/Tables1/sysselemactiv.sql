CREATE TABLE [dbo].[sysselemactiv] (
    [Host_id]        CHAR (10)  NOT NULL,
    [Host_name]      CHAR (30)  NOT NULL,
    [Aplicatia]      CHAR (30)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Utilizator]     CHAR (10)  NOT NULL,
    [Tip_act]        CHAR (1)   NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Fisa]           CHAR (10)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Numar_pozitie]  INT        NOT NULL,
    [Element]        CHAR (20)  NOT NULL,
    [Valoare]        FLOAT (53) NOT NULL,
    [Tip_document]   CHAR (2)   NOT NULL,
    [Numar_document] CHAR (8)   NOT NULL,
    [Data_document]  DATETIME   NOT NULL
) ON [SYSS];

