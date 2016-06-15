CREATE TABLE [dbo].[fisaUT] (
    [Subunitate]    CHAR (9)   NOT NULL,
    [Nr_inv]        CHAR (13)  NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Loc_munca]     CHAR (9)   NOT NULL,
    [Lucrat]        FLOAT (53) NOT NULL,
    [Rep_accid]     FLOAT (53) NOT NULL,
    [Mat_energ]     FLOAT (53) NOT NULL,
    [Comenzi]       FLOAT (53) NOT NULL,
    [Forta_munca]   FLOAT (53) NOT NULL,
    [Rep_planif]    FLOAT (53) NOT NULL,
    [Opriri_tehn]   FLOAT (53) NOT NULL,
    [Sch_neplanif]  FLOAT (53) NOT NULL,
    [Alte_intrerup] FLOAT (53) NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [FisaUT1]
    ON [dbo].[fisaUT]([Subunitate] ASC, [Nr_inv] ASC, [Loc_munca] ASC, [Data] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [FisaUT2]
    ON [dbo].[fisaUT]([Subunitate] ASC, [Loc_munca] ASC, [Nr_inv] ASC, [Data] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [FisaUT3]
    ON [dbo].[fisaUT]([Subunitate] ASC, [Nr_inv] ASC, [Data] ASC, [Loc_munca] ASC);

