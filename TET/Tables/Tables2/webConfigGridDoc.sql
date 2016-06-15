CREATE TABLE [dbo].[webConfigGridDoc] (
    [tipMacheta] VARCHAR (2)  NULL,
    [tipDoc]     VARCHAR (2)  NULL,
    [NumeCol]    VARCHAR (50) NULL,
    [DataField]  VARCHAR (50) NULL,
    [Vizibil]    BIT          NULL,
    [Ordine]     INT          NULL,
    [Latime]     INT          NULL,
    [TipDate]    VARCHAR (1)  NULL,
    [Detalii1]   VARCHAR (50) NULL,
    [Detalii2]   VARCHAR (50) NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [PrincwebConfigGridDoc]
    ON [dbo].[webConfigGridDoc]([tipMacheta] ASC, [tipDoc] ASC, [NumeCol] ASC, [DataField] ASC)
    ON [WEB];

