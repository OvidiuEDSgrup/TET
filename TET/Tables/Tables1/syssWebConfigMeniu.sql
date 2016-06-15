CREATE TABLE [dbo].[syssWebConfigMeniu] (
    [LogId]            INT            IDENTITY (1, 1) NOT NULL,
    [user_name]        VARCHAR (100)  NULL,
    [host_name]        VARCHAR (1000) NULL,
    [program_name]     VARCHAR (1000) NULL,
    [tip_operatie]     VARCHAR (1000) NULL,
    [data_modificarii] DATETIME       NULL,
    [Meniu]            VARCHAR (20)   NOT NULL,
    [Nume]             VARCHAR (30)   NULL,
    [MeniuParinte]     VARCHAR (20)   NULL,
    [Icoana]           VARCHAR (50)   NULL,
    [TipMacheta]       VARCHAR (5)    NULL,
    [NrOrdine]         DECIMAL (7, 2) NULL,
    [Componenta]       VARCHAR (100)  NULL,
    [Semnatura]        VARCHAR (100)  NULL,
    [Detalii]          XML            DEFAULT (NULL) NULL,
    [vizibil]          BIT            DEFAULT ((1)) NOT NULL,
    [publicabil]       INT            NULL,
    CONSTRAINT [PK__syssWebC__5E54864819D6E6B5] PRIMARY KEY CLUSTERED ([LogId] ASC) ON [SYSS]
);

