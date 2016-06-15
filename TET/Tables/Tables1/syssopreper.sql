CREATE TABLE [dbo].[syssopreper] (
    [Host_id]              CHAR (10)  NOT NULL,
    [Host_name]            CHAR (30)  NOT NULL,
    [Aplicatia]            CHAR (30)  NOT NULL,
    [Data_operarii]        DATETIME   NOT NULL,
    [Utilizator]           CHAR (10)  NOT NULL,
    [Tip_act]              CHAR (1)   NOT NULL,
    [Cod_reper]            CHAR (20)  NOT NULL,
    [Cod]                  CHAR (20)  NOT NULL,
    [Numar_operatie]       SMALLINT   NOT NULL,
    [Loc_de_munca]         CHAR (9)   NOT NULL,
    [Comanda]              CHAR (13)  NOT NULL,
    [Timp_de_pregatire]    FLOAT (53) NOT NULL,
    [Timp_util]            FLOAT (53) NOT NULL,
    [Categoria_salarizare] CHAR (4)   NOT NULL,
    [Norma_de_timp]        FLOAT (53) NOT NULL,
    [Tarif_unitar]         FLOAT (53) NOT NULL,
    [Cantitate_neta]       FLOAT (53) NOT NULL,
    [Lungime_dupa_op]      FLOAT (53) NOT NULL,
    [Latime_dupa_op]       FLOAT (53) NOT NULL,
    [Inaltime_dupa_op]     FLOAT (53) NOT NULL
) ON [SYSS];

