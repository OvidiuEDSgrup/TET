CREATE TABLE [dbo].[grmasini] (
    [Grupa]    CHAR (20) NOT NULL,
    [Denumire] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[grmasini]([Grupa] ASC);

