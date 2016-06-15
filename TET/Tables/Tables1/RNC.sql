CREATE TABLE [dbo].[RNC] (
    [Subunitate]        CHAR (9)   NOT NULL,
    [Nr_raport]         CHAR (8)   NOT NULL,
    [Data_raport]       DATETIME   NOT NULL,
    [Nr_matricol_inf]   CHAR (20)  NOT NULL,
    [Sir_matricole]     CHAR (200) NOT NULL,
    [Marca_CTC]         CHAR (6)   NOT NULL,
    [Comanda]           CHAR (13)  NOT NULL,
    [Produs]            CHAR (20)  NOT NULL,
    [Reper]             CHAR (20)  NOT NULL,
    [Nr_operatie]       SMALLINT   NOT NULL,
    [Operatie]          CHAR (20)  NOT NULL,
    [Loc_de_munca]      CHAR (9)   NOT NULL,
    [Cant_inspectata]   FLOAT (53) NOT NULL,
    [Cant_rebuturi]     FLOAT (53) NOT NULL,
    [Cant_reparata]     FLOAT (53) NOT NULL,
    [Total_timp]        FLOAT (53) NOT NULL,
    [Actiune_corectiva] CHAR (1)   NOT NULL,
    [Solutie_acceptata] BIT        NOT NULL,
    [Data_terminare]    DATETIME   NOT NULL,
    [Explicatii]        CHAR (100) NOT NULL,
    [Nr_pozitii]        FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [RNC1]
    ON [dbo].[RNC]([Subunitate] ASC, [Data_raport] ASC, [Nr_raport] ASC, [Nr_matricol_inf] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [RNC2]
    ON [dbo].[RNC]([Subunitate] ASC, [Nr_raport] ASC, [Data_raport] ASC, [Nr_matricol_inf] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [RNC3]
    ON [dbo].[RNC]([Subunitate] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Data_raport] ASC, [Nr_raport] ASC, [Nr_matricol_inf] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [RNC4]
    ON [dbo].[RNC]([Subunitate] ASC, [Comanda] ASC, [Loc_de_munca] ASC, [Data_raport] ASC, [Nr_raport] ASC, [Nr_matricol_inf] ASC);

