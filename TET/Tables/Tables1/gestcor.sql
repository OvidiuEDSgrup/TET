CREATE TABLE [dbo].[gestcor] (
    [Gestiune]     CHAR (9) NOT NULL,
    [Loc_de_munca] CHAR (9) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Gestcor]
    ON [dbo].[gestcor]([Gestiune] ASC);

