CREATE TABLE [dbo].[pretun] (
    [Data_lunii]               DATETIME   NOT NULL,
    [Subunitate]               CHAR (9)   NOT NULL,
    [Loc_de_munca]             CHAR (9)   NOT NULL,
    [Comanda]                  CHAR (13)  NOT NULL,
    [Cheltuieli_totale]        FLOAT (53) NOT NULL,
    [Cheltuieli_directe]       FLOAT (53) NOT NULL,
    [Cantitate]                FLOAT (53) NOT NULL,
    [Cantitate_regie_proprie]  FLOAT (53) NOT NULL,
    [Baza_de_calcul]           FLOAT (53) NOT NULL,
    [Baza_de_calcul_RG]        FLOAT (53) NOT NULL,
    [Baza_de_calcul_ch_aprov]  FLOAT (53) NOT NULL,
    [Baza_de_calcul_ch_desf]   FLOAT (53) NOT NULL,
    [Pret_unitar]              FLOAT (53) NOT NULL,
    [Cheltuieli_regie_proprie] FLOAT (53) NOT NULL,
    [Tip_comanda]              CHAR (1)   NOT NULL,
    [Poate_primi_cheltuieli]   BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Index_unic]
    ON [dbo].[pretun]([Subunitate] ASC, [Data_lunii] ASC, [Loc_de_munca] ASC, [Comanda] ASC);

