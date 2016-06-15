CREATE TABLE [dbo].[Posturi_de_lucru] (
    [Postul_de_lucru]       SMALLINT     NOT NULL,
    [Loc_de_munca]          VARCHAR (9)  NOT NULL,
    [Consilier_responsabil] VARCHAR (50) NOT NULL,
    [Denumire]              VARCHAR (50) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[Posturi_de_lucru]([Postul_de_lucru] ASC);

