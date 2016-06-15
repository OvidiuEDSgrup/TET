CREATE TABLE [dbo].[utlj] (
    [Cod]      CHAR (20)  NOT NULL,
    [Denumire] CHAR (100) NOT NULL,
    [UM]       CHAR (3)   NOT NULL,
    [Tarif]    FLOAT (53) NOT NULL,
    [Alfa1]    CHAR (20)  NOT NULL,
    [Alfa2]    CHAR (20)  NOT NULL,
    [Val1]     FLOAT (53) NOT NULL,
    [Val2]     FLOAT (53) NOT NULL,
    [Data]     DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Utlj1]
    ON [dbo].[utlj]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Utlj2]
    ON [dbo].[utlj]([Denumire] ASC);

