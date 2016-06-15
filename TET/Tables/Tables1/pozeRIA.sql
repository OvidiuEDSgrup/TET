CREATE TABLE [dbo].[pozeRIA] (
    [Tip]      CHAR (1)      NULL,
    [Cod]      CHAR (20)     NULL,
    [Pozitie]  INT           NULL,
    [Versiune] INT           NULL,
    [Fisier]   VARCHAR (255) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PrincPozeRia]
    ON [dbo].[pozeRIA]([Tip] ASC, [Cod] ASC, [Pozitie] ASC);

