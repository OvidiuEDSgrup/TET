CREATE TABLE [dbo].[antetinv] (
    [Tip]          CHAR (1)   NOT NULL,
    [Gestiune]     CHAR (9)   NOT NULL,
    [Data]         DATETIME   NOT NULL,
    [Locatie]      CHAR (30)  NOT NULL,
    [Blocat]       INT        NULL,
    [Data_inceput] DATETIME   NOT NULL,
    [Data_sfarsit] DATETIME   NOT NULL,
    [Alfa1]        CHAR (50)  NOT NULL,
    [Alfa2]        CHAR (3)   NOT NULL,
    [Val1]         FLOAT (53) NOT NULL,
    [Val2]         FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[antetinv]([Tip] ASC, [Gestiune] ASC, [Data] ASC, [Locatie] ASC);

