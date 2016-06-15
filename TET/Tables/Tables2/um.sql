CREATE TABLE [dbo].[um] (
    [UM]       CHAR (3)  NOT NULL,
    [Denumire] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UM]
    ON [dbo].[um]([UM] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[um]([Denumire] ASC);

