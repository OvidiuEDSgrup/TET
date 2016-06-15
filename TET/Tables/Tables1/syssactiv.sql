CREATE TABLE [dbo].[syssactiv] (
    [Host_id]       CHAR (10) NOT NULL,
    [Host_name]     CHAR (30) NOT NULL,
    [Aplicatia]     CHAR (30) NOT NULL,
    [Data_operarii] DATETIME  NOT NULL,
    [Utilizator]    CHAR (10) NOT NULL,
    [Tip_act]       CHAR (1)  NOT NULL,
    [Tip]           CHAR (2)  NOT NULL,
    [Fisa]          CHAR (10) NOT NULL,
    [Data]          DATETIME  NOT NULL,
    [Masina]        CHAR (20) NOT NULL,
    [Comanda]       CHAR (13) NOT NULL,
    [Loc_de_munca]  CHAR (9)  NOT NULL,
    [Comanda_benef] CHAR (13) NOT NULL,
    [lm_benef]      CHAR (9)  NOT NULL,
    [Tert]          CHAR (13) NOT NULL,
    [Marca]         CHAR (6)  NOT NULL,
    [Marca_ajutor]  CHAR (6)  NOT NULL,
    [Jurnal]        CHAR (3)  NOT NULL
) ON [SYSS];

