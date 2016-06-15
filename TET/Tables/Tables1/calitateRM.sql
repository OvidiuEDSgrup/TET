CREATE TABLE [dbo].[calitateRM] (
    [Subunitate]                 CHAR (9)   NOT NULL,
    [Tip]                        CHAR (2)   NOT NULL,
    [Numar]                      CHAR (8)   NOT NULL,
    [Data]                       DATETIME   NOT NULL,
    [Numar_pozitie]              INT        NOT NULL,
    [Nr_raport]                  CHAR (13)  NOT NULL,
    [Data_raport]                DATETIME   NOT NULL,
    [Densitate_de_lungime_ST]    CHAR (25)  NOT NULL,
    [Densitate_de_lungime_RA]    CHAR (25)  NOT NULL,
    [Tenacitate_ST]              CHAR (25)  NOT NULL,
    [Tenacitate_RA]              CHAR (25)  NOT NULL,
    [Alungire_rupere_ST]         CHAR (25)  NOT NULL,
    [Alungire_rupere_RA]         CHAR (25)  NOT NULL,
    [Torsiune_ST]                CHAR (25)  NOT NULL,
    [Torsiune_RA]                CHAR (25)  NOT NULL,
    [Contractie_ST]              CHAR (25)  NOT NULL,
    [Contractie_RA]              CHAR (25)  NOT NULL,
    [Nm_ST]                      CHAR (25)  NOT NULL,
    [Nm_RA]                      CHAR (25)  NOT NULL,
    [Coeficient_variatie_ST]     CHAR (25)  NOT NULL,
    [Coeficient_variatie_RA]     CHAR (25)  NOT NULL,
    [Coeficient_variatie_rez_ST] CHAR (25)  NOT NULL,
    [Coeficient_variatie_rez_RA] CHAR (25)  NOT NULL,
    [Sarcina_rupere_ST]          CHAR (25)  NOT NULL,
    [Sarcina_rupere_RA]          CHAR (25)  NOT NULL,
    [Obs]                        CHAR (200) NOT NULL,
    [Rezultat]                   CHAR (1)   NOT NULL,
    [Numar_RPN]                  CHAR (8)   NOT NULL,
    [Data_RPN]                   DATETIME   NOT NULL,
    [Cantitate_inspectata]       FLOAT (53) NOT NULL,
    [Cantitate_neconforma]       FLOAT (53) NOT NULL,
    [Contract]                   CHAR (20)  NOT NULL,
    [Data_comanda]               DATETIME   NOT NULL,
    [Clauza_contractuala]        CHAR (30)  NOT NULL,
    [Locul_constatarii]          CHAR (1)   NOT NULL,
    [Alt_loc_constatare]         CHAR (10)  NOT NULL,
    [Descriere_neconformitate]   CHAR (500) NOT NULL,
    [Persoana_constatatoare]     CHAR (20)  NOT NULL,
    [Inspector_CI]               CHAR (20)  NOT NULL,
    [Data_constatarii]           DATETIME   NOT NULL,
    [Tip_masuri_corectie]        CHAR (1)   NOT NULL,
    [Alte_masuri_corectie]       CHAR (15)  NOT NULL,
    [Numar_fisa]                 CHAR (10)  NOT NULL,
    [Data_fisa]                  DATETIME   NOT NULL,
    [Accept_ST]                  BIT        NOT NULL,
    [Cauze_neconformitate]       CHAR (200) NOT NULL,
    [Masuri_corective]           CHAR (500) NOT NULL,
    [Persoana_resp_corectie]     CHAR (20)  NOT NULL,
    [Data_cunostinta_corectie]   DATETIME   NOT NULL,
    [Data_planif_corectie]       DATETIME   NOT NULL,
    [Masuri_preventive]          CHAR (300) NOT NULL,
    [Persoana_resp_preventive]   CHAR (20)  NOT NULL,
    [Data_cunostinta_preventive] DATETIME   NOT NULL,
    [Data_planif_preventive]     DATETIME   NOT NULL,
    [Concluzii_masuri]           CHAR (300) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CalitRM]
    ON [dbo].[calitateRM]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Buletin_RM]
    ON [dbo].[calitateRM]([Subunitate] ASC, [Tip] ASC, [Nr_raport] ASC, [Data_raport] ASC);

