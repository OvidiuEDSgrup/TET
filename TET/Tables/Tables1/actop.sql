CREATE TABLE [dbo].[actop] (
    [Cod]          CHAR (20)   NOT NULL,
    [Descriere]    CHAR (255)  NOT NULL,
    [Explicatii]   CHAR (1000) NOT NULL,
    [Data_Jos]     DATETIME    NOT NULL,
    [Data_Sus]     DATETIME    NOT NULL,
    [Ora_Jos]      CHAR (6)    NOT NULL,
    [Ora_Sus]      CHAR (6)    NOT NULL,
    [Conditie]     CHAR (3000) NOT NULL,
    [Actiune]      CHAR (3000) NOT NULL,
    [Aplicatie]    CHAR (2)    NOT NULL,
    [Tip_document] CHAR (2)    NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal_discount]
    ON [dbo].[actop]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Cautare]
    ON [dbo].[actop]([Descriere] ASC);

