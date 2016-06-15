CREATE TABLE [dbo].[webConfigMeniuV2_0] (
    [id]         INT          NULL,
    [Nume]       VARCHAR (30) NULL,
    [idParinte]  INT          NULL,
    [Icoana]     VARCHAR (50) NULL,
    [TipMacheta] VARCHAR (5)  NULL,
    [Meniu]      VARCHAR (2)  NULL,
    [Modul]      VARCHAR (5)  NULL
) ON [WEB];

