CREATE TABLE [dbo].[cost] (
    [Data_lunii]                   DATETIME     NOT NULL,
    [Subunitate]                   CHAR (9)     NOT NULL,
    [Loc_de_munca]                 CHAR (9)     NOT NULL,
    [Comanda]                      CHAR (13)    NOT NULL,
    [Tip_comanda]                  CHAR (1)     NOT NULL,
    [Articol_de_calculatie]        CHAR (9)     NOT NULL,
    [Tip_inregistrare]             CHAR (2)     NOT NULL,
    [Valoare]                      FLOAT (53)   NOT NULL,
    [Valoare_fond_special]         FLOAT (53)   NOT NULL,
    [Cont_cheltuieli_sursa]        VARCHAR (20) NULL,
    [Loc_de_sursa]                 CHAR (9)     NOT NULL,
    [Comanda_sursa]                CHAR (13)    NOT NULL,
    [Articole_de_calculatie_sursa] CHAR (9)     NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Pt_calcul]
    ON [dbo].[cost]([Data_lunii] ASC, [Subunitate] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Articol_de_calculatie] ASC, [Tip_inregistrare] ASC, [Cont_cheltuieli_sursa] ASC, [Loc_de_sursa] ASC, [Comanda_sursa] ASC, [Articole_de_calculatie_sursa] ASC);


GO
CREATE NONCLUSTERED INDEX [Pt_situatie_postcalcul]
    ON [dbo].[cost]([Data_lunii] ASC, [Subunitate] ASC, [Comanda] ASC, [Loc_de_munca] ASC, [Articol_de_calculatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda]
    ON [dbo].[cost]([Subunitate] ASC, [Comanda] ASC);

