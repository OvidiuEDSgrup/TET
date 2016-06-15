CREATE TABLE [dbo].[sub] (
    [Subunitate]        CHAR (9)  NOT NULL,
    [Denumire]          CHAR (30) NOT NULL,
    [Nume_baza_de_date] CHAR (13) NOT NULL,
    [Tert]              CHAR (13) NOT NULL,
    [Ordonare]          INT       NOT NULL,
    [Indicator]         BIT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Sub]
    ON [dbo].[sub]([Subunitate] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[sub]([Denumire] ASC);


GO
CREATE NONCLUSTERED INDEX [Secundar]
    ON [dbo].[sub]([Ordonare] ASC);

