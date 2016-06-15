CREATE TABLE [dbo].[syssWebConfigFiltre] (
    [LogId]            INT            IDENTITY (1, 1) NOT NULL,
    [user_name]        VARCHAR (100)  NULL,
    [host_name]        VARCHAR (1000) NULL,
    [program_name]     VARCHAR (1000) NULL,
    [tip_operatie]     VARCHAR (1000) NULL,
    [data_modificarii] DATETIME       NULL,
    [Meniu]            VARCHAR (20)   NOT NULL,
    [Tip]              VARCHAR (2)    NOT NULL,
    [Ordine]           INT            NULL,
    [Vizibil]          BIT            NOT NULL,
    [TipObiect]        VARCHAR (50)   NULL,
    [Descriere]        VARCHAR (50)   NULL,
    [Prompt1]          VARCHAR (20)   NULL,
    [DataField1]       VARCHAR (100)  NULL,
    [Interval]         BIT            NULL,
    [Prompt2]          VARCHAR (20)   NULL,
    [DataField2]       VARCHAR (100)  NULL,
    [detalii]          XML            NULL,
    CONSTRAINT [PK__syssWebC__5E5486482825060C] PRIMARY KEY CLUSTERED ([LogId] ASC) ON [SYSS]
);

