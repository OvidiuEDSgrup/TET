CREATE TABLE [dbo].[syssWebConfigTaburi] (
    [LogId]            INT            IDENTITY (1, 1) NOT NULL,
    [user_name]        VARCHAR (100)  NULL,
    [host_name]        VARCHAR (1000) NULL,
    [program_name]     VARCHAR (1000) NULL,
    [tip_operatie]     VARCHAR (1000) NULL,
    [data_modificarii] DATETIME       NULL,
    [MeniuSursa]       VARCHAR (50)   NOT NULL,
    [TipSursa]         VARCHAR (50)   NOT NULL,
    [NumeTab]          VARCHAR (100)  NOT NULL,
    [Icoana]           VARCHAR (500)  NULL,
    [TipMachetaNoua]   VARCHAR (20)   NULL,
    [MeniuNou]         VARCHAR (20)   NULL,
    [TipNou]           VARCHAR (20)   NULL,
    [ProcPopulare]     VARCHAR (100)  NULL,
    [Ordine]           SMALLINT       NULL,
    [Vizibil]          BIT            NULL,
    [publicabil]       INT            DEFAULT ((1)) NULL,
    [detalii]          XML            NULL,
    CONSTRAINT [PK__syssWebC__5E5486482FC627D4] PRIMARY KEY CLUSTERED ([LogId] ASC) ON [SYSS]
);

