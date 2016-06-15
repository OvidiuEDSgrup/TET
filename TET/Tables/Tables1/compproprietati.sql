CREATE TABLE [dbo].[compproprietati] (
    [Cod_proprietate]        CHAR (20) NOT NULL,
    [Proprietate_componenta] CHAR (20) NOT NULL,
    [Numar_de_ordine]        INT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[compproprietati]([Cod_proprietate] ASC, [Numar_de_ordine] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Proprietati_componente]
    ON [dbo].[compproprietati]([Cod_proprietate] ASC, [Proprietate_componenta] ASC);

