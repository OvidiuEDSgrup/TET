CREATE TABLE [dbo].[misclocalizari] (
    [Id]             INT        IDENTITY (1, 1) NOT NULL,
    [Tip_obiect]     CHAR (20)  NOT NULL,
    [Obiect]         CHAR (20)  NOT NULL,
    [Localizare]     CHAR (20)  NOT NULL,
    [Data_miscarii]  DATETIME   NOT NULL,
    [Stare]          SMALLINT   NOT NULL,
    [Observatii]     CHAR (200) NOT NULL,
    [Tip_document]   CHAR (3)   NOT NULL,
    [Numar_document] CHAR (20)  NOT NULL,
    [Data_document]  DATETIME   NOT NULL,
    [Atasament]      IMAGE      NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[misclocalizari]([Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Obiect_si_data_desc]
    ON [dbo].[misclocalizari]([Tip_obiect] ASC, [Obiect] ASC, [Data_miscarii] DESC);


GO
CREATE NONCLUSTERED INDEX [Obiect_si_stare]
    ON [dbo].[misclocalizari]([Tip_obiect] ASC, [Obiect] ASC, [Stare] ASC);


GO
CREATE NONCLUSTERED INDEX [Localizare_si_stare]
    ON [dbo].[misclocalizari]([Localizare] ASC, [Stare] ASC);

