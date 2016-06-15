CREATE TABLE [dbo].[grcom] (
    [Tip_comanda]    CHAR (1)  NOT NULL,
    [Grupa]          CHAR (13) NOT NULL,
    [Denumire_grupa] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[grcom]([Tip_comanda] ASC, [Grupa] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire_grupa]
    ON [dbo].[grcom]([Denumire_grupa] ASC);


GO
CREATE NONCLUSTERED INDEX [Grupa]
    ON [dbo].[grcom]([Grupa] ASC);

