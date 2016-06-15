CREATE TABLE [dbo].[gterti] (
    [Grupa]            CHAR (3)  NOT NULL,
    [Denumire]         CHAR (30) NOT NULL,
    [Discount_acordat] REAL      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[gterti]([Grupa] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[gterti]([Denumire] ASC);

