CREATE TABLE [dbo].[grrapmt] (
    [Grupa]    CHAR (20) NOT NULL,
    [Denumire] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[grrapmt]([Grupa] ASC);

