CREATE TABLE [dbo].[valuta] (
    [Valuta]          CHAR (3)   NOT NULL,
    [Denumire_valuta] CHAR (30)  NOT NULL,
    [Curs_curent]     FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Valuta]
    ON [dbo].[valuta]([Valuta] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[valuta]([Denumire_valuta] ASC);

