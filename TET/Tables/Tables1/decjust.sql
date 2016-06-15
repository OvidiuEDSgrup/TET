CREATE TABLE [dbo].[decjust] (
    [DVE]             CHAR (13)  NOT NULL,
    [Data_DVE]        DATETIME   NOT NULL,
    [Tert]            CHAR (13)  NOT NULL,
    [DVI]             CHAR (13)  NOT NULL,
    [Data_DVI]        DATETIME   NOT NULL,
    [Nr_poz]          INT        NOT NULL,
    [Produs]          CHAR (20)  NOT NULL,
    [Cod_vamal_prod]  CHAR (20)  NOT NULL,
    [Valuta_DVE]      CHAR (3)   NOT NULL,
    [Curs_DVE]        FLOAT (53) NOT NULL,
    [Pret_prod]       FLOAT (53) NOT NULL,
    [Cant_prod]       FLOAT (53) NOT NULL,
    [Material]        CHAR (20)  NOT NULL,
    [Cod_vamal]       CHAR (20)  NOT NULL,
    [Cod_intrare]     CHAR (13)  NOT NULL,
    [Valuta_DVI]      CHAR (3)   NOT NULL,
    [Curs_DVI]        FLOAT (53) NOT NULL,
    [Pret_valuta]     FLOAT (53) NOT NULL,
    [Pret_stoc]       FLOAT (53) NOT NULL,
    [Cant_importata]  FLOAT (53) NOT NULL,
    [Cant_consumata]  FLOAT (53) NOT NULL,
    [Consum_specific] FLOAT (53) NOT NULL,
    [TVA]             FLOAT (53) NOT NULL,
    [Taxe_vam]        FLOAT (53) NOT NULL,
    [Com_vam]         FLOAT (53) NOT NULL,
    [Comanda]         CHAR (13)  NOT NULL,
    [Cant_mat_deseu]  FLOAT (53) NOT NULL,
    [TVA_deseu]       FLOAT (53) NOT NULL,
    [Taxe_vam_deseu]  FLOAT (53) NOT NULL,
    [Com_vam_deseu]   FLOAT (53) NOT NULL,
    [Nr_AP]           CHAR (8)   NOT NULL,
    [Nr_poz_AP]       INT        NOT NULL,
    [Randament]       FLOAT (53) NOT NULL,
    [Nr_RM]           CHAR (8)   NOT NULL,
    [Data_RM]         DATETIME   NOT NULL,
    [Nr_poz_RM]       INT        NOT NULL,
    [Termen]          DATETIME   NOT NULL,
    [Prelungire]      DATETIME   NOT NULL,
    [Val_RM]          FLOAT (53) NOT NULL,
    [TVA_RM]          FLOAT (53) NOT NULL,
    [Taxe_vam_RM]     FLOAT (53) NOT NULL,
    [Com_vam_RM]      FLOAT (53) NOT NULL,
    [Tip_taxe]        CHAR (13)  NOT NULL,
    [Cota_TVA]        FLOAT (53) NOT NULL,
    [Cota_taxe_vam]   FLOAT (53) NOT NULL,
    [Val1]            FLOAT (53) NOT NULL,
    [Val2]            FLOAT (53) NOT NULL,
    [Val3]            FLOAT (53) NOT NULL,
    [Val4]            FLOAT (53) NOT NULL,
    [Val5]            FLOAT (53) NOT NULL,
    [Val6]            FLOAT (53) NOT NULL,
    [Val7]            FLOAT (53) NOT NULL,
    [Val8]            FLOAT (53) NOT NULL,
    [Val9]            FLOAT (53) NOT NULL,
    [Alfa1]           CHAR (20)  NOT NULL,
    [Alfa2]           CHAR (20)  NOT NULL,
    [Alfa3]           CHAR (20)  NOT NULL,
    [Alfa4]           CHAR (20)  NOT NULL,
    [Alfa5]           CHAR (20)  NOT NULL,
    [Alfa6]           CHAR (20)  NOT NULL,
    [Data1]           DATETIME   NOT NULL,
    [Data2]           DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Dec_just]
    ON [dbo].[decjust]([DVE] ASC, [Data_DVE] ASC, [Tert] ASC, [DVI] ASC, [Data_DVI] ASC, [Nr_poz] ASC, [Produs] ASC, [Material] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Decjust2]
    ON [dbo].[decjust]([DVE] ASC, [Data_DVE] ASC, [Tert] ASC, [Nr_poz] ASC);


GO
CREATE NONCLUSTERED INDEX [Decjust3]
    ON [dbo].[decjust]([DVI] ASC, [Data_DVI] ASC, [Material] ASC, [Cod_intrare] ASC, [Comanda] ASC, [Data_DVE] ASC, [Nr_poz] ASC);

