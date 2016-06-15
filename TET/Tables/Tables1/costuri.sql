CREATE TABLE [dbo].[costuri] (
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
    ON [dbo].[costuri]([lm] ASC, [comanda] ASC);

