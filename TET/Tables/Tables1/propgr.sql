CREATE TABLE [dbo].[propgr] (
    [Tip]             CHAR (1)  NOT NULL,
    [Grupa]           CHAR (13) NOT NULL,
    [Numar]           SMALLINT  NOT NULL,
    [Cod_proprietate] CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ProprGr]
    ON [dbo].[propgr]([Tip] ASC, [Grupa] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Proprietate]
    ON [dbo].[propgr]([Cod_proprietate] ASC);

