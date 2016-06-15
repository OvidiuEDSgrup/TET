CREATE TABLE [dbo].[gesttmpid] (
    [Hostid]   CHAR (8) NOT NULL,
    [Gestiune] CHAR (9) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Cod_gest]
    ON [dbo].[gesttmpid]([Hostid] ASC, [Gestiune] ASC);

