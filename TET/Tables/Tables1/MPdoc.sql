CREATE TABLE [dbo].[MPdoc] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Numar]          CHAR (20)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Schimb]         FLOAT (53) NOT NULL,
    [Sarja]          FLOAT (53) NOT NULL,
    [Gest_prod]      CHAR (20)  NOT NULL,
    [Gest_mat]       CHAR (20)  NOT NULL,
    [Loc_munca]      CHAR (20)  NOT NULL,
    [Loc_munca_prim] CHAR (20)  NOT NULL,
    [Utilaj]         CHAR (20)  NOT NULL,
    [Utilaj_prim]    CHAR (20)  NOT NULL,
    [Comanda]        CHAR (20)  NOT NULL,
    [Sef_schimb]     CHAR (20)  NOT NULL,
    [Mecanic_schimb] CHAR (20)  NOT NULL,
    [Nr_pers_schimb] FLOAT (53) NOT NULL,
    [Alfa1]          CHAR (20)  NOT NULL,
    [Alfa2]          CHAR (20)  NOT NULL,
    [Alfa3]          CHAR (30)  NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Val3]           FLOAT (53) NOT NULL,
    [Stare]          CHAR (1)   NOT NULL,
    [Nr_pozitii]     FLOAT (53) NOT NULL,
    [Utilizator]     CHAR (10)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Ora_operarii]   CHAR (6)   NOT NULL,
    [Jurnal]         CHAR (20)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [MPdoc1]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MPdoc2]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Jurnal] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdoc3]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Data] ASC, [Schimb] ASC, [Sarja] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdoc4]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Loc_munca_prim] ASC, [Utilaj_prim] ASC, [Data] ASC, [Schimb] ASC, [Sarja] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MPdoc5]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Jurnal] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdoc6]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Loc_munca] ASC, [Val1] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdoc7]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Loc_munca] ASC, [Utilaj] ASC, [Val1] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdoc8]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Schimb] ASC, [Sarja] ASC, [Loc_munca] ASC, [Utilaj] ASC);


GO
CREATE NONCLUSTERED INDEX [MPdoc9]
    ON [dbo].[MPdoc]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Schimb] ASC, [Sarja] ASC, [Loc_munca_prim] ASC, [Utilaj_prim] ASC);

