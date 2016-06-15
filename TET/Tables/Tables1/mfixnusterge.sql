CREATE TABLE [dbo].[mfixnusterge] (
    [Subunitate]                CHAR (9)  NOT NULL,
    [Numar_de_inventar]         CHAR (13) NOT NULL,
    [Denumire]                  CHAR (80) NOT NULL,
    [Serie]                     CHAR (20) NOT NULL,
    [Tip_amortizare]            CHAR (1)  NOT NULL,
    [Cod_de_clasificare]        CHAR (13) NOT NULL,
    [Data_punerii_in_functiune] DATETIME  NOT NULL
);

