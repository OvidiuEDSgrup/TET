CREATE TABLE [dbo].[JurnalDocumente] (
    [idJurnal]      INT           IDENTITY (1, 1) NOT NULL,
    [tip]           VARCHAR (5)   NULL,
    [numar]         VARCHAR (20)  NULL,
    [data]          DATETIME      NULL,
    [data_operatii] DATETIME      DEFAULT (getdate()) NULL,
    [stare]         INT           NULL,
    [explicatii]    VARCHAR (600) NULL,
    [detalii]       XML           NULL,
    [utilizator]    VARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([idJurnal] ASC)
);


GO
CREATE NONCLUSTERED INDEX [pIDX]
    ON [dbo].[JurnalDocumente]([tip] ASC, [numar] ASC, [data] ASC);

