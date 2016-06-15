CREATE TABLE [dbo].[syssmatrep] (
    [Host_id]                CHAR (10)  NOT NULL,
    [Host_name]              CHAR (30)  NOT NULL,
    [Aplicatia]              CHAR (30)  NOT NULL,
    [Data_operarii]          DATETIME   NOT NULL,
    [Utilizator]             CHAR (10)  NOT NULL,
    [Tip_act]                CHAR (1)   NOT NULL,
    [Cod_reper]              CHAR (20)  NOT NULL,
    [Cod_material]           CHAR (20)  NOT NULL,
    [Cod_operatie]           CHAR (20)  NOT NULL,
    [Numar_material]         SMALLINT   NOT NULL,
    [Tip_material]           CHAR (1)   NOT NULL,
    [_supr]                  FLOAT (53) NOT NULL,
    [Coeficient_de_consum]   FLOAT (53) NOT NULL,
    [Randament_de_utilizare] FLOAT (53) NOT NULL,
    [Consum_specific]        FLOAT (53) NOT NULL,
    [Cod_inlocuit]           CHAR (20)  NOT NULL,
    [Loc_de_munca]           CHAR (13)  NOT NULL,
    [Observatii]             CHAR (200) NOT NULL
) ON [SYSS];

