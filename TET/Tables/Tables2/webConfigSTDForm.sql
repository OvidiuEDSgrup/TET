CREATE TABLE [dbo].[webConfigSTDForm] (
    [Meniu]         VARCHAR (20)  NOT NULL,
    [Tip]           VARCHAR (20)  NULL,
    [Subtip]        VARCHAR (20)  NULL,
    [Ordine]        INT           NULL,
    [Nume]          VARCHAR (50)  NULL,
    [TipObiect]     VARCHAR (50)  NULL,
    [DataField]     VARCHAR (50)  NULL,
    [LabelField]    VARCHAR (50)  NULL,
    [Latime]        INT           NULL,
    [Vizibil]       BIT           NULL,
    [Modificabil]   BIT           NULL,
    [ProcSQL]       VARCHAR (50)  NULL,
    [ListaValori]   VARCHAR (100) NULL,
    [ListaEtichete] VARCHAR (600) NULL,
    [Initializare]  VARCHAR (50)  NULL,
    [Prompt]        VARCHAR (50)  NULL,
    [Procesare]     VARCHAR (50)  NULL,
    [Tooltip]       VARCHAR (500) NULL,
    [formula]       VARCHAR (MAX) NULL,
    [detalii]       XML           NULL
);

