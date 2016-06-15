CREATE TABLE [dbo].[consdet] (
    [Numar]             CHAR (13)  NOT NULL,
    [Data]              DATETIME   NOT NULL,
    [Schimb]            SMALLINT   NOT NULL,
    [Loc_de_munca]      CHAR (13)  NOT NULL,
    [Reper]             CHAR (20)  NOT NULL,
    [Material]          CHAR (20)  NOT NULL,
    [Cod_inlocuit]      CHAR (20)  NOT NULL,
    [Normat_inlocuitor] FLOAT (53) NOT NULL,
    [Normat_inlocuit]   FLOAT (53) NOT NULL,
    [Consum_sugerat]    FLOAT (53) NOT NULL,
    [Consum_efectiv]    FLOAT (53) NOT NULL,
    [Stare]             FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Consdet1]
    ON [dbo].[consdet]([Loc_de_munca] ASC, [Data] ASC, [Schimb] ASC, [Reper] ASC, [Material] ASC, [Cod_inlocuit] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Consdet2]
    ON [dbo].[consdet]([Loc_de_munca] ASC, [Data] ASC, [Schimb] ASC, [Cod_inlocuit] ASC, [Reper] ASC, [Material] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Consdet3]
    ON [dbo].[consdet]([Numar] ASC, [Data] ASC, [Reper] ASC, [Material] ASC, [Cod_inlocuit] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Consdet4]
    ON [dbo].[consdet]([Numar] ASC, [Data] ASC, [Cod_inlocuit] ASC, [Reper] ASC, [Material] ASC);

