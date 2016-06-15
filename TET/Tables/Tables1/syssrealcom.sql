CREATE TABLE [dbo].[syssrealcom] (
    [Host_id]              CHAR (10)  NOT NULL,
    [Host_name]            CHAR (30)  NOT NULL,
    [Aplicatia]            CHAR (30)  NOT NULL,
    [Data_operarii]        DATETIME   NOT NULL,
    [Utilizator]           CHAR (10)  NOT NULL,
    [Tip_act]              CHAR (1)   NOT NULL,
    [Marca]                CHAR (6)   NOT NULL,
    [Loc_de_munca]         CHAR (9)   NOT NULL,
    [Numar_document]       CHAR (20)  NOT NULL,
    [Data]                 DATETIME   NOT NULL,
    [Comanda]              CHAR (13)  NOT NULL,
    [Cod_reper]            CHAR (20)  NOT NULL,
    [Cod]                  CHAR (20)  NOT NULL,
    [Cantitate]            FLOAT (53) NOT NULL,
    [Categoria_salarizare] CHAR (4)   NOT NULL,
    [Norma_de_timp]        FLOAT (53) NOT NULL,
    [Tarif_unitar]         FLOAT (53) NOT NULL
) ON [SYSS];

