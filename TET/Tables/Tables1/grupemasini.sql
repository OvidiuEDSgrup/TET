CREATE TABLE [dbo].[grupemasini] (
    [Grupa]      CHAR (3)  NOT NULL,
    [Denumire]   CHAR (30) NOT NULL,
    [tip_masina] CHAR (20) NOT NULL,
    [detalii]    XML       NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[grupemasini]([Grupa] ASC);

