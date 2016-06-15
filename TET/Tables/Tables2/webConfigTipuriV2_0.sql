CREATE TABLE [dbo].[webConfigTipuriV2_0] (
    [IdUtilizator]    VARCHAR (10)  NULL,
    [TipMacheta]      VARCHAR (2)   NOT NULL,
    [Meniu]           VARCHAR (2)   NOT NULL,
    [Tip]             VARCHAR (2)   NULL,
    [Subtip]          VARCHAR (2)   NULL,
    [Ordine]          INT           NULL,
    [Nume]            VARCHAR (50)  NULL,
    [Descriere]       VARCHAR (500) NULL,
    [TextAdaugare]    VARCHAR (60)  NULL,
    [TextModificare]  VARCHAR (60)  NULL,
    [ProcDate]        VARCHAR (60)  NULL,
    [ProcScriere]     VARCHAR (60)  NULL,
    [ProcStergere]    VARCHAR (60)  NULL,
    [ProcDatePoz]     VARCHAR (60)  NULL,
    [ProcScrierePoz]  VARCHAR (60)  NULL,
    [ProcStergerePoz] VARCHAR (60)  NULL,
    [Vizibil]         BIT           NULL
) ON [WEB];

