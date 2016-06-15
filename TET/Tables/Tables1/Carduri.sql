CREATE TABLE [dbo].[Carduri] (
    [Data]  DATETIME   NOT NULL,
    [Marca] CHAR (6)   NOT NULL,
    [Nume]  CHAR (50)  NOT NULL,
    [Cont]  CHAR (25)  NOT NULL,
    [Suma]  FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Carduri]([Data] ASC, [Marca] ASC, [Cont] ASC);

