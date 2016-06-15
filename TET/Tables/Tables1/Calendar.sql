CREATE TABLE [dbo].[Calendar] (
    [Data]       DATETIME  NOT NULL,
    [Explicatii] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data]
    ON [dbo].[Calendar]([Data] ASC);

