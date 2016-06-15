CREATE TABLE [dbo].[analize] (
    [Subunitate]       CHAR (9)   NOT NULL,
    [Nr_buletin]       CHAR (18)  NOT NULL,
    [Data_buletin]     DATETIME   NOT NULL,
    [Tip_doc]          CHAR (2)   NOT NULL,
    [Nr_doc]           CHAR (8)   NOT NULL,
    [Data_doc]         DATETIME   NOT NULL,
    [Tert]             CHAR (13)  NOT NULL,
    [Gest]             CHAR (9)   NOT NULL,
    [Cod]              CHAR (20)  NOT NULL,
    [Cod_intr]         CHAR (13)  NOT NULL,
    [Nr_poz_doc]       INT        NOT NULL,
    [Gest_prim]        CHAR (9)   NOT NULL,
    [Cod_intr_prim]    CHAR (13)  NOT NULL,
    [Contract]         CHAR (20)  NOT NULL,
    [Nr_doc_exped]     CHAR (8)   NOT NULL,
    [Mijloc_transp]    CHAR (1)   NOT NULL,
    [Nr_mijloc_transp] CHAR (20)  NOT NULL,
    [Cant_furn]        FLOAT (53) NOT NULL,
    [Cant_fizica]      FLOAT (53) NOT NULL,
    [Cant_utila]       FLOAT (53) NOT NULL,
    [Cant_stoc]        FLOAT (53) NOT NULL,
    [Plata_la_util]    BIT        NOT NULL,
    [Pret]             FLOAT (53) NOT NULL,
    [Tara_furn]        FLOAT (53) NOT NULL,
    [Tara_reala]       FLOAT (53) NOT NULL,
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
    [Culoare]          CHAR (20)  NOT NULL,
    [Infestare]        CHAR (20)  NOT NULL,
    [Miros]            CHAR (20)  NOT NULL,
    [Mh_decontare]     FLOAT (53) NOT NULL,
    [Umid_decontare]   FLOAT (53) NOT NULL,
    [Cs_decontare]     FLOAT (53) NOT NULL,
    [Ind1_decontare]   FLOAT (53) NOT NULL,
    [Ind2_decontare]   FLOAT (53) NOT NULL,
    [Ind3_decontare]   FLOAT (53) NOT NULL,
    [Ora_intrarii]     CHAR (6)   NOT NULL,
    [Ora_iesirii]      CHAR (6)   NOT NULL,
    [Tip_misc]         CHAR (1)   NOT NULL,
    [Utilizator]       CHAR (10)  NOT NULL,
    [Data_operarii]    DATETIME   NOT NULL,
    [Ora_operarii]     CHAR (6)   NOT NULL,
    [Jurnal]           CHAR (3)   NOT NULL,
    [Csv_decontare]    FLOAT (53) NOT NULL,
    [Taxa_uscare]      FLOAT (53) NOT NULL,
    [Usc_fact]         CHAR (1)   NOT NULL,
    [Rez1]             CHAR (13)  NOT NULL,
    [Rez2]             CHAR (13)  NOT NULL,
    [Rez3]             CHAR (13)  NOT NULL,
    [Rez4]             FLOAT (53) NOT NULL,
    [Data_rez]         DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Analize1]
    ON [dbo].[analize]([Subunitate] ASC, [Tip_doc] ASC, [Nr_doc] ASC, [Data_doc] ASC, [Nr_poz_doc] ASC, [Tert] ASC, [Cod] ASC, [Nr_buletin] ASC, [Data_buletin] ASC);


GO
CREATE NONCLUSTERED INDEX [Analize2]
    ON [dbo].[analize]([Subunitate] ASC, [Tip_doc] ASC, [Data_buletin] ASC, [Nr_buletin] ASC, [Jurnal] ASC, [Data_doc] ASC, [Nr_doc] ASC, [Usc_fact] ASC);


GO
CREATE NONCLUSTERED INDEX [Analize3]
    ON [dbo].[analize]([Subunitate] ASC, [Tip_doc] ASC, [Nr_buletin] ASC, [Data_buletin] ASC, [Jurnal] ASC, [Nr_doc] ASC, [Data_doc] ASC, [Usc_fact] ASC);


GO
CREATE NONCLUSTERED INDEX [Analize4]
    ON [dbo].[analize]([Subunitate] ASC, [Gest] ASC, [Cod] ASC, [Cod_intr] ASC, [Nr_poz_doc] ASC);


GO
CREATE NONCLUSTERED INDEX [Analize5]
    ON [dbo].[analize]([Subunitate] ASC, [Gest_prim] ASC, [Cod] ASC, [Cod_intr_prim] ASC, [Nr_poz_doc] ASC);


GO
CREATE NONCLUSTERED INDEX [Analize6]
    ON [dbo].[analize]([Subunitate] ASC, [Gest] ASC, [Cod] ASC, [Cod_intr] ASC, [Data_doc] ASC, [Tip_misc] ASC, [Nr_poz_doc] ASC);


GO
CREATE NONCLUSTERED INDEX [Analize7]
    ON [dbo].[analize]([Subunitate] ASC, [Gest_prim] ASC, [Cod] ASC, [Cod_intr_prim] ASC, [Data_doc] ASC, [Tip_misc] ASC, [Nr_poz_doc] ASC);

