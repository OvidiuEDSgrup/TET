CREATE TABLE [dbo].[prefproptmp] (
    [Hostid]          CHAR (8)   NOT NULL,
    [Tip]             CHAR (20)  NOT NULL,
    [Cod_proprietate] CHAR (20)  NOT NULL,
    [Valoare]         CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[prefproptmp]([Hostid] ASC, [Tip] ASC, [Cod_proprietate] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip]
    ON [dbo].[prefproptmp]([Hostid] ASC, [Tip] ASC);

