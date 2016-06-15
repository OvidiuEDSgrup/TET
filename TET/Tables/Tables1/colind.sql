CREATE TABLE [dbo].[colind] (
    [Cod_indicator] VARCHAR (20) NOT NULL,
    [Numar]         SMALLINT     NOT NULL,
    [Denumire]      VARCHAR (30) NOT NULL,
    [Tip_grafic]    VARCHAR (30) NULL,
    [Procedura]     VARCHAR (50) NULL,
    [Tip_filtru]    VARCHAR (50) NULL,
    [tipSortare]    SMALLINT     DEFAULT ((0)) NULL,
    CONSTRAINT [CK_tipuri_fitru] CHECK (isnull([tip_filtru],'')='dropdown' OR isnull([tip_filtru],'')='slicer' OR isnull([tip_filtru],'')='')
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal_coloane]
    ON [dbo].[colind]([Cod_indicator] ASC, [Numar] ASC);

