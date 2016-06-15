CREATE TABLE [dbo].[webConfigDetaliiOp] (
    [tipMacheta]        VARCHAR (2)   NULL,
    [Descriere]         VARCHAR (50)  NULL,
    [DataField]         VARCHAR (50)  NULL,
    [Ordine]            INT           NULL,
    [Latime]            INT           NULL,
    [tipObiect]         VARCHAR (5)   NULL,
    [procSQL]           VARCHAR (40)  NULL,
    [listaValori]       VARCHAR (60)  NULL,
    [listaEtichete]     VARCHAR (250) NULL,
    [DataFieldValidare] VARCHAR (50)  NULL,
    [Initializare]      VARCHAR (50)  NULL,
    [TextValidare]      VARCHAR (50)  NULL,
    [Prompt]            VARCHAR (50)  NULL,
    [Vizibil]           BIT           NOT NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[webConfigDetaliiOp]([tipMacheta] ASC, [Ordine] ASC)
    ON [WEB];

