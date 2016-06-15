CREATE TABLE [dbo].[docfiscalerezervate] (
    [idPlaja]  INT      NOT NULL,
    [numar]    INT      NULL,
    [expirala] DATETIME NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PK_docfiscalerezervate]
    ON [dbo].[docfiscalerezervate]([idPlaja] ASC, [numar] ASC);

