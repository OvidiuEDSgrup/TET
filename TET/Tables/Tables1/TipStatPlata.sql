CREATE TABLE [dbo].[TipStatPlata] (
    [Tip_stat_plata] VARCHAR (25) NULL,
    [denumire]       VARCHAR (50) NULL,
    [idPozitie]      INT          IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY NONCLUSTERED ([idPozitie] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [TipStat]
    ON [dbo].[TipStatPlata]([Tip_stat_plata] ASC);

