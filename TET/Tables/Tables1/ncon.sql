CREATE TABLE [dbo].[ncon] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Numar]          CHAR (13)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Jurnal]         CHAR (3)   NOT NULL,
    [Nr_pozitii]     INT        NOT NULL,
    [Valuta]         CHAR (3)   NOT NULL,
    [Curs]           FLOAT (53) NOT NULL,
    [Valoare]        FLOAT (53) NOT NULL,
    [Valoare_valuta] FLOAT (53) NOT NULL,
    [Stare]          SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Nc]
    ON [dbo].[ncon]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Nc1]
    ON [dbo].[ncon]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Jurnal] ASC);

