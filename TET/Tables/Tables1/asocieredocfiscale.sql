CREATE TABLE [dbo].[asocieredocfiscale] (
    [Id]          INT       NOT NULL,
    [TipAsociere] CHAR (1)  NOT NULL,
    [Cod]         CHAR (20) NOT NULL,
    [Prioritate]  SMALLINT  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[asocieredocfiscale]([Id] ASC, [TipAsociere] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Dupa_tip_asociere]
    ON [dbo].[asocieredocfiscale]([TipAsociere] ASC, [Cod] ASC, [Prioritate] ASC);

