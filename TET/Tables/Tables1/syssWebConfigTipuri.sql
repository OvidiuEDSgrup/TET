﻿CREATE TABLE [dbo].[syssWebConfigTipuri] (
    [LogId]                INT            IDENTITY (1, 1) NOT NULL,
    [user_name]            VARCHAR (100)  NULL,
    [host_name]            VARCHAR (1000) NULL,
    [program_name]         VARCHAR (1000) NULL,
    [tip_operatie]         VARCHAR (1000) NULL,
    [data_modificarii]     DATETIME       NULL,
    [Meniu]                VARCHAR (20)   NOT NULL,
    [Tip]                  VARCHAR (2)    NULL,
    [Subtip]               VARCHAR (2)    NULL,
    [Ordine]               INT            NULL,
    [Nume]                 VARCHAR (50)   NULL,
    [Descriere]            VARCHAR (500)  NULL,
    [TextAdaugare]         VARCHAR (60)   NULL,
    [TextModificare]       VARCHAR (60)   NULL,
    [ProcDate]             VARCHAR (60)   NULL,
    [ProcScriere]          VARCHAR (60)   NULL,
    [ProcStergere]         VARCHAR (60)   NULL,
    [ProcDatePoz]          VARCHAR (60)   NULL,
    [ProcScrierePoz]       VARCHAR (60)   NULL,
    [ProcStergerePoz]      VARCHAR (60)   NULL,
    [Vizibil]              BIT            NULL,
    [Fel]                  VARCHAR (1)    NULL,
    [procPopulare]         VARCHAR (60)   NULL,
    [tasta]                VARCHAR (20)   NULL,
    [publicabil]           INT            DEFAULT ((1)) NULL,
    [ProcInchidereMacheta] VARCHAR (60)   NULL,
    [detalii]              XML            NULL,
    CONSTRAINT [PK__syssWebC__5E5486481F8FC00B] PRIMARY KEY CLUSTERED ([LogId] ASC) ON [SYSS]
);

