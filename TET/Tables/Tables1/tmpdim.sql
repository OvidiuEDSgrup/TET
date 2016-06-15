CREATE TABLE [dbo].[tmpdim] (
    [Lungime] REAL NOT NULL,
    [Latime]  REAL NOT NULL,
    [Bucati]  REAL NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Redim]
    ON [dbo].[tmpdim]([Lungime] ASC, [Latime] ASC);

