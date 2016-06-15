CREATE TABLE [dbo].[syssret] (
    [Host_id]                     CHAR (10)  NOT NULL,
    [Host_name]                   CHAR (30)  NOT NULL,
    [Aplicatia]                   CHAR (30)  NOT NULL,
    [Data_operarii]               DATETIME   NOT NULL,
    [Utilizator]                  CHAR (10)  NOT NULL,
    [Tip_act]                     CHAR (1)   NOT NULL,
    [Data]                        DATETIME   NOT NULL,
    [Marca]                       CHAR (6)   NOT NULL,
    [Cod_beneficiar]              CHAR (13)  NOT NULL,
    [Numar_document]              CHAR (10)  NOT NULL,
    [Data_document]               DATETIME   NOT NULL,
    [Valoare_totala_pe_doc]       FLOAT (53) NOT NULL,
    [Valoare_retinuta_pe_doc]     FLOAT (53) NOT NULL,
    [Retinere_progr_la_avans]     FLOAT (53) NOT NULL,
    [Retinere_progr_la_lichidare] FLOAT (53) NOT NULL,
    [Procent_progr_la_lichidare]  REAL       NOT NULL,
    [Retinut_la_avans]            FLOAT (53) NOT NULL,
    [Retinut_la_lichidare]        FLOAT (53) NOT NULL
) ON [SYSS];

