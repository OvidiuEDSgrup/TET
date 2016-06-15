CREATE TABLE [dbo].[tmpmeniumodule] (
    [Aplicatie] CHAR (2)   NOT NULL,
    [Modul]     SMALLINT   NOT NULL,
    [Descriere] CHAR (200) NOT NULL,
    [Actiune]   SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[tmpmeniumodule]([Modul] ASC);

