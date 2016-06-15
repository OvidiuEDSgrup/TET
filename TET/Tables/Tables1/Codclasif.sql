CREATE TABLE [dbo].[Codclasif] (
    [Cod_de_clasificare] CHAR (13)  NOT NULL,
    [Denumire]           CHAR (400) NOT NULL,
    [Este_grup]          BIT        NOT NULL,
    [DUR_min]            SMALLINT   NOT NULL,
    [DUR_max]            SMALLINT   NOT NULL,
    [DUR]                SMALLINT   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Codclasif]([Cod_de_clasificare] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[Codclasif]([Denumire] ASC);

