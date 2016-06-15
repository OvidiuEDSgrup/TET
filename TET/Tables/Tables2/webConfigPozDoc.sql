CREATE TABLE [dbo].[webConfigPozDoc] (
    [tipMacheta]    VARCHAR (2)  NULL,
    [tipDoc]        VARCHAR (2)  NULL,
    [Descriere]     VARCHAR (50) NULL,
    [DataField]     VARCHAR (50) NULL,
    [LabelField]    VARCHAR (50) NULL,
    [Grid]          INT          NULL,
    [LatimeGrid]    INT          NULL,
    [Input]         INT          NULL,
    [LatimeInput]   INT          NULL,
    [Detaliu]       INT          NULL,
    [LatimeDetaliu] INT          NULL,
    [tipDate]       VARCHAR (5)  NULL,
    [procSQL]       VARCHAR (40) NULL,
    [Procesare]     BIT          NULL,
    [Vizibil]       BIT          NOT NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [PrincwebConfigPozDoc]
    ON [dbo].[webConfigPozDoc]([tipMacheta] ASC, [tipDoc] ASC, [DataField] ASC)
    ON [WEB];

