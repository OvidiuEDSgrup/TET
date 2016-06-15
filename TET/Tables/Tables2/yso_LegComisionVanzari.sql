CREATE TABLE [dbo].[yso_LegComisionVanzari] (
    [idLegDoc] INT         IDENTITY (1, 1) NOT NULL,
    [subDoc]   VARCHAR (9) NOT NULL,
    [tipDoc]   VARCHAR (2) NOT NULL,
    [dataDoc]  DATETIME    NULL,
    [nrDoc]    VARCHAR (8) NOT NULL,
    [idPozDoc] INT         NOT NULL,
    PRIMARY KEY CLUSTERED ([idLegDoc] ASC),
    FOREIGN KEY ([idPozDoc]) REFERENCES [dbo].[pozdoc] ([idPozDoc]),
    FOREIGN KEY ([subDoc], [tipDoc], [dataDoc], [nrDoc]) REFERENCES [dbo].[doc] ([Subunitate], [Tip], [Data], [Numar]),
    UNIQUE NONCLUSTERED ([subDoc] ASC, [tipDoc] ASC, [dataDoc] ASC, [nrDoc] ASC)
);

