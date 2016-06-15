CREATE TABLE [dbo].[costuriSQL] (
    [Data]        DATETIME     NOT NULL,
    [lm]          VARCHAR (13) NULL,
    [comanda]     VARCHAR (13) NULL,
    [costuri]     FLOAT (53)   NULL,
    [cantitate]   FLOAT (53)   NULL,
    [pret]        FLOAT (53)   NULL,
    [rezolvat]    INT          NULL,
    [nerezolvate] FLOAT (53)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [princ]
    ON [dbo].[costuriSQL]([Data] ASC, [lm] ASC, [comanda] ASC);

