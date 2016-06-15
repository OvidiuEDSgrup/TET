CREATE TABLE [dbo].[istjudzone] (
    [Data]    DATETIME NOT NULL,
    [Divizia] CHAR (9) NOT NULL,
    [Judet]   CHAR (3) NOT NULL,
    [Zona]    CHAR (8) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Pincipal]
    ON [dbo].[istjudzone]([Data] DESC, [Divizia] ASC, [Judet] ASC, [Zona] ASC);

