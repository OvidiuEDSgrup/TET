CREATE TABLE [dbo].[sysscatop] (
    [Host_id]        CHAR (10)  NOT NULL,
    [Host_name]      CHAR (30)  NOT NULL,
    [Aplicatia]      CHAR (30)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Utilizator]     CHAR (10)  NOT NULL,
    [Tip_act]        CHAR (1)   NOT NULL,
    [Cod]            CHAR (20)  NOT NULL,
    [Denumire]       CHAR (350) NOT NULL,
    [UM]             CHAR (3)   NOT NULL,
    [Tip_operatie]   CHAR (13)  NOT NULL,
    [Numar_pozitii]  FLOAT (53) NOT NULL,
    [Numar_persoane] FLOAT (53) NOT NULL,
    [Tarif]          FLOAT (53) NOT NULL,
    [Categorie]      CHAR (20)  NOT NULL
) ON [SYSS];

