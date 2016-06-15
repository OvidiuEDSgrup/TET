CREATE TABLE [dbo].[syssWebConfigGrid] (
    [LogId]            INT            IDENTITY (1, 1) NOT NULL,
    [user_name]        VARCHAR (100)  NULL,
    [host_name]        VARCHAR (1000) NULL,
    [program_name]     VARCHAR (1000) NULL,
    [tip_operatie]     VARCHAR (1000) NULL,
    [data_modificarii] DATETIME       NULL,
    [Meniu]            VARCHAR (20)   NOT NULL,
    [Tip]              VARCHAR (2)    NULL,
    [Subtip]           VARCHAR (2)    NULL,
    [InPozitii]        BIT            NOT NULL,
    [NumeCol]          VARCHAR (50)   NULL,
    [DataField]        VARCHAR (50)   NULL,
    [TipObiect]        VARCHAR (50)   NULL,
    [Latime]           INT            NULL,
    [Ordine]           INT            NULL,
    [Vizibil]          BIT            NULL,
    [modificabil]      BIT            NULL,
    [formula]          VARCHAR (8000) NULL,
    [detalii]          XML            NULL,
    CONSTRAINT [PK__syssWebC__5E5486482BF596F0] PRIMARY KEY CLUSTERED ([LogId] ASC) ON [SYSS]
);

