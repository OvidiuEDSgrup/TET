CREATE TABLE [dbo].[reallmun] (
    [Data]                   DATETIME   NOT NULL,
    [Loc_de_munca]           CHAR (9)   NOT NULL,
    [Valoare_manopera]       FLOAT (53) NOT NULL,
    [Coeficient_de_acord]    FLOAT (53) NOT NULL,
    [Coeficient_de_timp]     FLOAT (53) NOT NULL,
    [Ore_realizate_in_acord] REAL       NOT NULL,
    [Salar_pontaj]           FLOAT (53) NOT NULL,
    [Ore_pontaj]             INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Loc_munca]
    ON [dbo].[reallmun]([Data] ASC, [Loc_de_munca] ASC);

