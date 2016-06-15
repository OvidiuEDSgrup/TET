CREATE TABLE [dbo].[investitii] (
    [Data_an]        DATETIME   NOT NULL,
    [Loc_de_munca]   CHAR (9)   NOT NULL,
    [Sursa]          CHAR (20)  NOT NULL,
    [Tip]            CHAR (1)   NOT NULL,
    [Valoare]        FLOAT (53) NOT NULL,
    [Valuta]         CHAR (3)   NOT NULL,
    [Curs]           FLOAT (53) NOT NULL,
    [Valoare_valuta] FLOAT (53) NOT NULL,
    [Explicatii]     CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[investitii]([Data_an] ASC, [Loc_de_munca] ASC, [Sursa] ASC, [Tip] ASC);

