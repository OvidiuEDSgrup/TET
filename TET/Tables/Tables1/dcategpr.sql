CREATE TABLE [dbo].[dcategpr] (
    [Tip]           CHAR (1)   NOT NULL,
    [Categ]         CHAR (13)  NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Pret]          FLOAT (53) NOT NULL,
    [Cont]          CHAR (13)  NOT NULL,
    [Mod_facturare] CHAR (1)   NOT NULL,
    [Cota_din_val]  FLOAT (53) NOT NULL,
    [Majorari]      FLOAT (53) NOT NULL,
    [Penalitati]    FLOAT (53) NOT NULL,
    [Zile_pt_pen]   FLOAT (53) NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL,
    [Cota_perioada] FLOAT (53) NOT NULL,
    [Data_inceput]  DATETIME   NOT NULL,
    [Data_sfarsit]  DATETIME   NOT NULL,
    [Alfa1]         CHAR (13)  NOT NULL,
    [Alfa2]         CHAR (13)  NOT NULL,
    [Val1]          FLOAT (53) NOT NULL,
    [Val2]          FLOAT (53) NOT NULL,
    [Data_rez]      DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Dcategpr1]
    ON [dbo].[dcategpr]([Tip] ASC, [Categ] ASC, [Data] DESC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Dcategpr2]
    ON [dbo].[dcategpr]([Tip] ASC, [Categ] ASC, [Data] ASC);

