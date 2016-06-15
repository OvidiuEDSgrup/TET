CREATE TABLE [dbo].[cercodnom] (
    [IdCerere]    CHAR (20)  NOT NULL,
    [Data]        DATETIME   NOT NULL,
    [Utilizator]  CHAR (10)  NOT NULL,
    [Descriere]   CHAR (200) NOT NULL,
    [Stare]       CHAR (1)   NOT NULL,
    [Raspuns]     CHAR (200) NOT NULL,
    [DataR]       DATETIME   NOT NULL,
    [UtilizatorR] CHAR (10)  NOT NULL,
    [Val1]        CHAR (30)  NULL,
    [Val2]        CHAR (30)  NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[cercodnom]([IdCerere] ASC);


GO
CREATE NONCLUSTERED INDEX [Utiliz_stare]
    ON [dbo].[cercodnom]([IdCerere] ASC, [Utilizator] ASC, [Stare] ASC);

