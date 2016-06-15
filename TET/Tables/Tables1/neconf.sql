CREATE TABLE [dbo].[neconf] (
    [Cod]       CHAR (20)  NOT NULL,
    [Descriere] CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Neconf1]
    ON [dbo].[neconf]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Neconf2]
    ON [dbo].[neconf]([Descriere] ASC);

