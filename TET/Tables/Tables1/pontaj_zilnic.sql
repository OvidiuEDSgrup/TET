CREATE TABLE [dbo].[pontaj_zilnic] (
    [idPontaj]     INT         IDENTITY (1, 1) NOT NULL,
    [data]         DATETIME    NULL,
    [marca]        VARCHAR (6) NULL,
    [loc_de_munca] VARCHAR (9) NULL,
    [tip_ore]      VARCHAR (3) NULL,
    [ore]          INT         NULL,
    [detalii]      XML         NULL,
    PRIMARY KEY CLUSTERED ([idPontaj] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[pontaj_zilnic]([data] ASC, [marca] ASC, [loc_de_munca] ASC, [tip_ore] ASC);

