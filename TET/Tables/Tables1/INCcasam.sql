CREATE TABLE [dbo].[INCcasam] (
    [Tip_casam]     CHAR (20) NOT NULL,
    [Tip_incasare]  CHAR (2)  NOT NULL,
    [Identificator] CHAR (20) NOT NULL,
    [Ordine]        SMALLINT  NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[INCcasam]([Tip_casam] ASC, [Tip_incasare] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar_de_ordine]
    ON [dbo].[INCcasam]([Ordine] ASC);

