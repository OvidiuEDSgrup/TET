CREATE TABLE [dbo].[grpind] (
    [Grup]          CHAR (1)  NOT NULL,
    [Denumire_grup] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[grpind]([Grup] ASC);

