CREATE TABLE [dbo].[sysspi] (
    [Host_id]        CHAR (10)    NOT NULL,
    [Host_name]      CHAR (30)    NOT NULL,
    [Aplicatia]      CHAR (30)    NOT NULL,
    [Data_stergerii] DATETIME     NOT NULL,
    [Stergator]      CHAR (10)    NOT NULL,
    [Marca]          VARCHAR (6)  NOT NULL,
    [Tip_intretinut] VARCHAR (1)  NOT NULL,
    [Cod_personal]   VARCHAR (13) NOT NULL,
    [Nume_pren]      VARCHAR (50) NOT NULL,
    [Data]           DATETIME     NOT NULL,
    [Grad_invalid]   VARCHAR (1)  NOT NULL,
    [Coef_ded]       REAL         NOT NULL,
    [Data_nasterii]  DATETIME     NOT NULL
);

