CREATE TABLE [dbo].[raspchestionar] (
    [Tert]             CHAR (13)  NOT NULL,
    [Chestionar]       CHAR (13)  NOT NULL,
    [Nr_Intrebare]     SMALLINT   NOT NULL,
    [Raspuns_numeric]  FLOAT (53) NOT NULL,
    [Raspuns_caracter] CHAR (30)  NOT NULL,
    [Raspuns_grila1]   BIT        NOT NULL,
    [Raspuns_grila2]   BIT        NOT NULL,
    [Raspuns_grila3]   BIT        NOT NULL,
    [Raspuns_grila4]   BIT        NOT NULL,
    [Raspuns_grila5]   BIT        NOT NULL,
    [Raspuns_grila6]   BIT        NOT NULL,
    [Raspuns]          CHAR (30)  NOT NULL,
    [Raspuns_grila7]   BIT        NOT NULL,
    [Raspuns_grila8]   BIT        NOT NULL,
    [Raspuns_grila9]   BIT        NOT NULL,
    [Raspuns_grila10]  BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [unic]
    ON [dbo].[raspchestionar]([Tert] ASC, [Chestionar] ASC, [Nr_Intrebare] ASC);

