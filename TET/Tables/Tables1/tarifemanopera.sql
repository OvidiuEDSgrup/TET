CREATE TABLE [dbo].[tarifemanopera] (
    [Cod]      VARCHAR (5)  NOT NULL,
    [Denumire] VARCHAR (50) NOT NULL,
    [Tarif]    FLOAT (53)   NOT NULL,
    [Valuta]   VARCHAR (3)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[tarifemanopera]([Cod] ASC);

