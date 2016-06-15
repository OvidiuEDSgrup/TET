CREATE TABLE [dbo].[declaratii] (
    [idDeclaratie]  INT          IDENTITY (1, 1) NOT NULL,
    [Cod]           VARCHAR (20) NOT NULL,
    [Tip]           VARCHAR (1)  NOT NULL,
    [Data]          DATETIME     NOT NULL,
    [Utilizator]    VARCHAR (20) NOT NULL,
    [Data_operarii] DATETIME     NOT NULL,
    [Detalii]       XML          NULL,
    [Continut]      XML          NULL,
    PRIMARY KEY NONCLUSTERED ([idDeclaratie] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[declaratii]([Cod] ASC, [Tip] ASC, [Data] ASC);

