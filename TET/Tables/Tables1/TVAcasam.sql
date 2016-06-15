CREATE TABLE [dbo].[TVAcasam] (
    [Tip_casam]     CHAR (20) NOT NULL,
    [Cota_TVA]      REAL      NOT NULL,
    [Identificator] CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [TVA_casa_unic]
    ON [dbo].[TVAcasam]([Tip_casam] ASC, [Cota_TVA] ASC);

