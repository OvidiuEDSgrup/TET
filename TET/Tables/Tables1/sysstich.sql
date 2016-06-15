CREATE TABLE [dbo].[sysstich] (
    [Host_id]          CHAR (10)  NOT NULL,
    [Host_name]        CHAR (30)  NOT NULL,
    [Aplicatia]        CHAR (30)  NOT NULL,
    [Data_operarii]    DATETIME   NOT NULL,
    [Utilizator]       CHAR (10)  NOT NULL,
    [Tip_act]          CHAR (1)   NOT NULL,
    [Marca]            CHAR (6)   NOT NULL,
    [Data_lunii]       DATETIME   NOT NULL,
    [Tip_operatie]     CHAR (1)   NOT NULL,
    [Serie_inceput]    CHAR (13)  NOT NULL,
    [Serie_sfarsit]    CHAR (13)  NOT NULL,
    [Nr_tichete]       REAL       NOT NULL,
    [Valoare_tichet]   FLOAT (53) NOT NULL,
    [Valoare_imprimat] FLOAT (53) NOT NULL,
    [TVA_imprimat]     FLOAT (53) NOT NULL
) ON [SYSS];

