CREATE TABLE [dbo].[formSQL] (
    [Terminal] CHAR (8)    NOT NULL,
    [Rand]     INT         NOT NULL,
    [Text]     CHAR (1000) NOT NULL,
    CONSTRAINT [Principal] PRIMARY KEY CLUSTERED ([Terminal] ASC, [Rand] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Pe_terminal]
    ON [dbo].[formSQL]([Terminal] ASC);

