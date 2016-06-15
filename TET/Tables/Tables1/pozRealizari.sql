CREATE TABLE [dbo].[pozRealizari] (
    [id]          INT           IDENTITY (1, 1) NOT NULL,
    [idLegatura]  INT           NOT NULL,
    [idRealizare] INT           NOT NULL,
    [tip]         VARCHAR (2)   NULL,
    [cantitate]   FLOAT (53)    NULL,
    [observatii]  VARCHAR (400) NULL,
    [CM]          VARCHAR (13)  NULL,
    [PP]          VARCHAR (13)  NULL,
    [detalii]     XML           NULL,
    [data_start]  DATETIME      NULL,
    [data_stop]   DATETIME      NULL
);


GO
CREATE NONCLUSTERED INDEX [princ]
    ON [dbo].[pozRealizari]([idRealizare] ASC, [idLegatura] ASC, [tip] ASC) WITH (FILLFACTOR = 20);

