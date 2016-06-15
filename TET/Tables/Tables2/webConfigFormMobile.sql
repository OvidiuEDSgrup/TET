CREATE TABLE [dbo].[webConfigFormMobile] (
    [Identificator] VARCHAR (100) NOT NULL,
    [Ordine]        FLOAT (53)    NULL,
    [Nume]          VARCHAR (50)  NULL,
    [TipObiect]     VARCHAR (50)  NULL,
    [DataField]     VARCHAR (50)  NULL,
    [LabelField]    VARCHAR (50)  NULL,
    [ProcSQL]       VARCHAR (50)  NULL,
    [ListaValori]   VARCHAR (100) NULL,
    [ListaEtichete] VARCHAR (600) NULL,
    [Initializare]  VARCHAR (50)  NULL,
    [Prompt]        VARCHAR (50)  NULL,
    [Vizibil]       BIT           DEFAULT ((1)) NULL,
    [Modificabil]   BIT           DEFAULT ((1)) NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [PrincwebConfigFormMobile]
    ON [dbo].[webConfigFormMobile]([Identificator] ASC, [DataField] ASC)
    ON [WEB];

