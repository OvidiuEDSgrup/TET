CREATE TABLE [dbo].[curs] (
    [Valuta] CHAR (3)   NOT NULL,
    [Data]   DATETIME   NOT NULL,
    [Tip]    CHAR (1)   NOT NULL,
    [Curs]   FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Valuta]
    ON [dbo].[curs]([Valuta] ASC, [Data] DESC, [Tip] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[curs]([Data] ASC);

