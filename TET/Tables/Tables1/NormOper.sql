CREATE TABLE [dbo].[NormOper] (
    [Tip]       CHAR (1)  NOT NULL,
    [Cod]       CHAR (20) NOT NULL,
    [Variabila] SMALLINT  NOT NULL,
    [Procent]   REAL      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[NormOper]([Tip] ASC, [Cod] ASC, [Variabila] ASC);

