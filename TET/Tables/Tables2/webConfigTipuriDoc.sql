CREATE TABLE [dbo].[webConfigTipuriDoc] (
    [tipMacheta]  VARCHAR (2)  NULL,
    [Ordine]      INT          NULL,
    [tipDocument] VARCHAR (2)  NULL,
    [Label]       VARCHAR (30) NULL,
    [Vizibil]     BIT          NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[webConfigTipuriDoc]([tipMacheta] ASC, [tipDocument] ASC)
    ON [WEB];


GO
CREATE NONCLUSTERED INDEX [Macheta]
    ON [dbo].[webConfigTipuriDoc]([tipMacheta] ASC, [Ordine] ASC)
    ON [WEB];

