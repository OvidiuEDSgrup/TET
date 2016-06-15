CREATE TABLE [dbo].[docAnalize] (
    [Subunitate]       CHAR (9)   NOT NULL,
    [Tip_doc]          CHAR (2)   NOT NULL,
    [Nr_doc]           CHAR (8)   NOT NULL,
    [Data_doc]         DATETIME   NOT NULL,
    [Nr_poz_doc]       INT        NOT NULL,
    [Stare]            SMALLINT   NOT NULL,
    [Tert]             CHAR (13)  NOT NULL,
    [Gest]             CHAR (9)   NOT NULL,
    [Cod]              CHAR (20)  NOT NULL,
    [Loc_munca]        CHAR (9)   NOT NULL,
    [Contract]         CHAR (20)  NOT NULL,
    [Factura]          CHAR (20)  NOT NULL,
    [Cont_factura]     CHAR (13)  NOT NULL,
    [Data_facturii]    DATETIME   NOT NULL,
    [Mijloc_transp]    CHAR (1)   NOT NULL,
    [Nr_mijloc_transp] CHAR (20)  NOT NULL,
    [Delegat]          CHAR (20)  NOT NULL,
    [Buletin]          CHAR (13)  NOT NULL,
    [Cant_fizica]      FLOAT (53) NOT NULL,
    [Tara_reala]       FLOAT (53) NOT NULL,
    [Cant_stoc]        FLOAT (53) NOT NULL,
    [Cant_utila]       FLOAT (53) NOT NULL,
    [Plata_la_util]    BIT        NOT NULL,
    [Pret]             FLOAT (53) NOT NULL,
    [Tara_furn]        FLOAT (53) NOT NULL,
    [Cant_furn]        FLOAT (53) NOT NULL,
    [Nr_buletin]       CHAR (18)  NOT NULL,
    [Data_buletin]     DATETIME   NOT NULL,
    [Soi_FS]           REAL       NOT NULL,
    [Mh_furn]          FLOAT (53) NOT NULL,
    [Mh_doc]           FLOAT (53) NOT NULL,
    [Umid_furn]        FLOAT (53) NOT NULL,
    [Umid_doc]         FLOAT (53) NOT NULL,
    [Cs_furn]          FLOAT (53) NOT NULL,
    [Csa_doc]          FLOAT (53) NOT NULL,
    [Csn_doc]          FLOAT (53) NOT NULL,
    [Gl]               FLOAT (53) NOT NULL,
    [Ig]               FLOAT (53) NOT NULL,
    [Id]               FLOAT (53) NOT NULL,
    [Sticl]            FLOAT (53) NOT NULL,
    [Ic]               FLOAT (53) NOT NULL,
    [Ind1]             FLOAT (53) NOT NULL,
    [Ind2]             FLOAT (53) NOT NULL,
    [Ind3]             FLOAT (53) NOT NULL,
    [Ind4]             FLOAT (53) NOT NULL,
    [Ind5]             FLOAT (53) NOT NULL,
    [Culoare]          CHAR (25)  NOT NULL,
    [Infestare]        CHAR (25)  NOT NULL,
    [Miros]            CHAR (25)  NOT NULL,
    [Mh_decontare]     FLOAT (53) NOT NULL,
    [Umid_decontare]   FLOAT (53) NOT NULL,
    [Cs_decontare]     FLOAT (53) NOT NULL,
    [Ind1_decontare]   FLOAT (53) NOT NULL,
    [Ind2_decontare]   FLOAT (53) NOT NULL,
    [Ind3_decontare]   FLOAT (53) NOT NULL,
    [Ora_intrarii]     CHAR (6)   NOT NULL,
    [Ora_iesirii]      CHAR (6)   NOT NULL,
    [Tip_misc]         CHAR (20)  NOT NULL,
    [Utilizator]       CHAR (10)  NOT NULL,
    [Data_operarii]    DATETIME   NOT NULL,
    [Ora_operarii]     CHAR (6)   NOT NULL,
    [Jurnal]           CHAR (20)  NOT NULL,
    [Csv_decontare]    FLOAT (53) NOT NULL,
    [Taxa_uscare]      FLOAT (53) NOT NULL,
    [Usc_fact]         CHAR (13)  NOT NULL,
    [Cantitate1]       FLOAT (53) NOT NULL,
    [Cantitate2]       FLOAT (53) NOT NULL,
    [Termen_livrare]   DATETIME   NOT NULL,
    [Rez3]             CHAR (20)  NOT NULL,
    [Datorie_rec]      FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Analize1]
    ON [dbo].[docAnalize]([Subunitate] ASC, [Tip_doc] ASC, [Nr_doc] ASC, [Data_doc] ASC, [Nr_poz_doc] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Analize2]
    ON [dbo].[docAnalize]([Subunitate] ASC, [Tip_doc] ASC, [Data_buletin] ASC, [Nr_buletin] ASC, [Nr_poz_doc] ASC);


GO
CREATE NONCLUSTERED INDEX [Analize4]
    ON [dbo].[docAnalize]([Subunitate] ASC, [Gest] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Analize5]
    ON [dbo].[docAnalize]([Subunitate] ASC, [Loc_munca] ASC, [Cod] ASC);

