CREATE TABLE [dbo].[necfRNC] (
    [Subunitate]       CHAR (9)   NOT NULL,
    [Tip_specificatie] CHAR (1)   NOT NULL,
    [Nr_raport]        CHAR (8)   NOT NULL,
    [Data_raport]      DATETIME   NOT NULL,
    [Nr_matricol_inf]  CHAR (20)  NOT NULL,
    [Sir_matricole]    CHAR (200) NOT NULL,
    [Marca_CTC]        CHAR (6)   NOT NULL,
    [Comanda]          CHAR (13)  NOT NULL,
    [Produs]           CHAR (20)  NOT NULL,
    [Reper]            CHAR (20)  NOT NULL,
    [Nr_operatie]      SMALLINT   NOT NULL,
    [Operatie]         CHAR (20)  NOT NULL,
    [Cant_reper]       FLOAT (53) NOT NULL,
    [Neconformitate]   CHAR (20)  NOT NULL,
    [Loc_de_munca]     CHAR (9)   NOT NULL,
    [Timp_reparatie]   FLOAT (53) NOT NULL,
    [Nr_pozitii]       FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [NecfRNC1]
    ON [dbo].[necfRNC]([Subunitate] ASC, [Tip_specificatie] ASC, [Data_raport] ASC, [Nr_raport] ASC, [Nr_matricol_inf] ASC, [Neconformitate] ASC, [Loc_de_munca] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [NecfRNC2]
    ON [dbo].[necfRNC]([Subunitate] ASC, [Tip_specificatie] ASC, [Nr_raport] ASC, [Data_raport] ASC, [Nr_matricol_inf] ASC, [Loc_de_munca] ASC, [Neconformitate] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [NecfRNC3]
    ON [dbo].[necfRNC]([Subunitate] ASC, [Tip_specificatie] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Data_raport] ASC, [Nr_raport] ASC, [Nr_matricol_inf] ASC, [Neconformitate] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [NecfRNC4]
    ON [dbo].[necfRNC]([Subunitate] ASC, [Tip_specificatie] ASC, [Comanda] ASC, [Loc_de_munca] ASC, [Data_raport] ASC, [Nr_raport] ASC, [Nr_matricol_inf] ASC, [Neconformitate] ASC);

