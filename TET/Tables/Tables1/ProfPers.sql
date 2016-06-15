CREATE TABLE [dbo].[ProfPers] (
    [Marca]          CHAR (6)  NOT NULL,
    [Profesia]       CHAR (10) NOT NULL,
    [Data_inceperii] DATETIME  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[ProfPers]([Marca] ASC, [Profesia] ASC);


GO
CREATE NONCLUSTERED INDEX [Detaliere]
    ON [dbo].[ProfPers]([Marca] ASC, [Data_inceperii] ASC, [Profesia] ASC);

