CREATE TABLE [dbo].[campSIT] (
    [Tip_lista]    CHAR (13) NOT NULL,
    [Numar_curent] SMALLINT  NOT NULL,
    [Cod]          CHAR (13) NOT NULL,
    [Ordine]       SMALLINT  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [tmpregp_01]
    ON [dbo].[campSIT]([Tip_lista] ASC, [Numar_curent] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [tmpregp_02]
    ON [dbo].[campSIT]([Tip_lista] ASC, [Ordine] ASC);

