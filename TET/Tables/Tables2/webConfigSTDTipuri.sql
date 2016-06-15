CREATE TABLE [dbo].[webConfigSTDTipuri] (
    [Meniu]                VARCHAR (20)  NOT NULL,
    [Tip]                  VARCHAR (20)  NULL,
    [Subtip]               VARCHAR (20)  NULL,
    [Ordine]               INT           NULL,
    [Nume]                 VARCHAR (50)  NULL,
    [Descriere]            VARCHAR (500) NULL,
    [TextAdaugare]         VARCHAR (60)  NULL,
    [TextModificare]       VARCHAR (60)  NULL,
    [ProcDate]             VARCHAR (60)  NULL,
    [ProcScriere]          VARCHAR (60)  NULL,
    [ProcStergere]         VARCHAR (60)  NULL,
    [ProcDatePoz]          VARCHAR (60)  NULL,
    [ProcScrierePoz]       VARCHAR (60)  NULL,
    [ProcStergerePoz]      VARCHAR (60)  NULL,
    [Vizibil]              BIT           NULL,
    [Fel]                  VARCHAR (1)   NULL,
    [procPopulare]         VARCHAR (60)  NULL,
    [tasta]                VARCHAR (20)  NULL,
    [ProcInchidereMacheta] VARCHAR (60)  NULL
);

