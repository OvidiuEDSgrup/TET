CREATE TABLE [dbo].[rotunj] (
    [Limita] FLOAT (53) NOT NULL,
    [Suma]   FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Limita]
    ON [dbo].[rotunj]([Limita] ASC);

