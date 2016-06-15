CREATE TABLE [dbo].[tipproprietati] (
    [Tip]             CHAR (20) NOT NULL,
    [Cod_proprietate] CHAR (20) NOT NULL,
    [NrOrdine]        INT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[tipproprietati]([Tip] ASC, [Cod_proprietate] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar_de_ordine]
    ON [dbo].[tipproprietati]([NrOrdine] ASC);

