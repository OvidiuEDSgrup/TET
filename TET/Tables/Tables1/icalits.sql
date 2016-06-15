CREATE TABLE [dbo].[icalits] (
    [Subunitate] CHAR (9)   NOT NULL,
    [Data]       DATETIME   NOT NULL,
    [Tip_gest]   CHAR (1)   NOT NULL,
    [Gest]       CHAR (9)   NOT NULL,
    [Cod]        CHAR (20)  NOT NULL,
    [Cod_intr]   CHAR (13)  NOT NULL,
    [Stoc_init]  FLOAT (53) NOT NULL,
    [Intrari]    FLOAT (53) NOT NULL,
    [Iesiri]     FLOAT (53) NOT NULL,
    [Stoc]       FLOAT (53) NOT NULL,
    [Mh_init]    FLOAT (53) NOT NULL,
    [Mh]         FLOAT (53) NOT NULL,
    [Umid_init]  FLOAT (53) NOT NULL,
    [Umid]       FLOAT (53) NOT NULL,
    [Csa_init]   FLOAT (53) NOT NULL,
    [Csa]        FLOAT (53) NOT NULL,
    [Csn_init]   FLOAT (53) NOT NULL,
    [Csn]        FLOAT (53) NOT NULL,
    [Gl_init]    FLOAT (53) NOT NULL,
    [Gl]         FLOAT (53) NOT NULL,
    [Ig_init]    FLOAT (53) NOT NULL,
    [Ig]         FLOAT (53) NOT NULL,
    [Id_init]    FLOAT (53) NOT NULL,
    [Id]         FLOAT (53) NOT NULL,
    [Sticl_init] FLOAT (53) NOT NULL,
    [Sticl]      FLOAT (53) NOT NULL,
    [Ic_init]    FLOAT (53) NOT NULL,
    [Ic]         FLOAT (53) NOT NULL,
    [Ind1_init]  FLOAT (53) NOT NULL,
    [Ind1]       FLOAT (53) NOT NULL,
    [Ind2_init]  FLOAT (53) NOT NULL,
    [Ind2]       FLOAT (53) NOT NULL,
    [Ind3_init]  FLOAT (53) NOT NULL,
    [Ind3]       FLOAT (53) NOT NULL,
    [Ind4_init]  FLOAT (53) NOT NULL,
    [Ind4]       FLOAT (53) NOT NULL,
    [Ind5_init]  FLOAT (53) NOT NULL,
    [Ind5]       FLOAT (53) NOT NULL,
    [Rez1]       CHAR (13)  NOT NULL,
    [Rez2]       CHAR (13)  NOT NULL,
    [Rez3]       CHAR (13)  NOT NULL,
    [Data_rez]   DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Icalits1]
    ON [dbo].[icalits]([Subunitate] ASC, [Tip_gest] ASC, [Gest] ASC, [Cod] ASC, [Cod_intr] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Icalits2]
    ON [dbo].[icalits]([Subunitate] ASC, [Cod] ASC, [Tip_gest] ASC, [Gest] ASC, [Cod_intr] ASC);


GO
CREATE NONCLUSTERED INDEX [Icalits3]
    ON [dbo].[icalits]([Subunitate] ASC, [Cod] ASC, [Stoc] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Icalits4]
    ON [dbo].[icalits]([Subunitate] ASC, [Tip_gest] ASC, [Gest] ASC, [Cod] ASC, [Data] DESC, [Cod_intr] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Icalits5]
    ON [dbo].[icalits]([Subunitate] ASC, [Tip_gest] ASC, [Gest] ASC, [Cod] ASC, [Data] ASC, [Cod_intr] ASC);

