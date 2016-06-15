CREATE TABLE [dbo].[tet_sezonalitate] (
    [Data_lunii] DATETIME   NOT NULL,
    [An]         SMALLINT   NOT NULL,
    [Luna]       SMALLINT   NOT NULL,
    [LunaAlfa]   CHAR (15)  NOT NULL,
    [Trimestru]  SMALLINT   NOT NULL,
    [Procent]    FLOAT (53) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[tet_sezonalitate]([Data_lunii] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Luna]
    ON [dbo].[tet_sezonalitate]([An] ASC, [Luna] ASC);

