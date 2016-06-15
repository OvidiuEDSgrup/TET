CREATE TABLE [dbo].[coefic] (
    [Data_lunii]                DATETIME    NOT NULL,
    [Subunitate]                VARCHAR (9) NOT NULL,
    [Tip_coeficient]            VARCHAR (1) NOT NULL,
    [Loc_de_munca]              VARCHAR (9) NOT NULL,
    [Baza_initiala]             FLOAT (53)  NOT NULL,
    [Baza_actualizata]          FLOAT (53)  NOT NULL,
    [Cheltuieli_initiale]       FLOAT (53)  NOT NULL,
    [Cheltuieli_actualizate]    FLOAT (53)  NOT NULL,
    [Coeficient_initial]        FLOAT (53)  NOT NULL,
    [Coeficient_actualizat]     FLOAT (53)  NOT NULL,
    [Cheltuieli_initiale_FS]    FLOAT (53)  NOT NULL,
    [Cheltuieli_actualizate_FS] FLOAT (53)  NOT NULL,
    [Coeficient_initial_FS]     FLOAT (53)  NOT NULL,
    [Coeficient_actualizat_FS]  FLOAT (53)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Index_unic]
    ON [dbo].[coefic]([Data_lunii] ASC, [Subunitate] ASC, [Tip_coeficient] ASC, [Loc_de_munca] ASC);

