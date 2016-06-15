CREATE TABLE [dbo].[tiputil] (
    [Tip]          CHAR (20) NOT NULL,
    [Denumire]     CHAR (30) NOT NULL,
    [Loc_de_munca] CHAR (9)  NOT NULL,
    [Turatie]      REAL      NOT NULL,
    [Nr_mersuri]   REAL      NOT NULL,
    [Mod_inreg]    CHAR (1)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Tip_utilaj]
    ON [dbo].[tiputil]([Tip] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[tiputil]([Denumire] ASC);


GO
CREATE NONCLUSTERED INDEX [Loc_de_munca]
    ON [dbo].[tiputil]([Loc_de_munca] ASC, [Tip] ASC);

