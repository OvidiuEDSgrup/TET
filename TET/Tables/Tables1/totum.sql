CREATE TABLE [dbo].[totum] (
    [Terminal]     SMALLINT   NOT NULL,
    [Loc_de_munca] CHAR (9)   NOT NULL,
    [UM]           CHAR (3)   NOT NULL,
    [Stoc_initial] FLOAT (53) NOT NULL,
    [Intrari]      FLOAT (53) NOT NULL,
    [Iesiri]       FLOAT (53) NOT NULL,
    [Stoc_final]   FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[totum]([Terminal] ASC, [Loc_de_munca] ASC, [UM] ASC);

