CREATE TABLE [dbo].[Cursor_Pontaj] (
    [HostID]           CHAR (8)   NOT NULL,
    [Marca]            CHAR (6)   NOT NULL,
    [Loc_de_munca]     CHAR (9)   NOT NULL,
    [Regim_de_lucru]   REAL       NOT NULL,
    [Grupa_de_munca]   CHAR (1)   NOT NULL,
    [Tip_salarizare]   CHAR (1)   NOT NULL,
    [Coeficient_acord] FLOAT (53) NOT NULL,
    [Ore_intr_tehn_2]  SMALLINT   NOT NULL,
    [Ore_intemperii]   SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[Cursor_Pontaj]([HostID] ASC, [Marca] ASC, [Loc_de_munca] ASC);

