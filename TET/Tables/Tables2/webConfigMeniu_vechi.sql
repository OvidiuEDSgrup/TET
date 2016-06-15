CREATE TABLE [dbo].[webConfigMeniu_vechi] (
    [id]         INT          NULL,
    [Nume]       VARCHAR (30) NULL,
    [idParinte]  INT          NULL,
    [Icoana]     VARCHAR (50) NULL,
    [TipMacheta] VARCHAR (5)  NULL,
    [Meniu]      VARCHAR (2)  NULL,
    [Modul]      VARCHAR (5)  NULL,
    [detalii]    XML          NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [pMeniu]
    ON [dbo].[webConfigMeniu_vechi]([id] ASC, [Nume] ASC, [idParinte] ASC)
    ON [WEB];

