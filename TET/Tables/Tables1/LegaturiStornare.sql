CREATE TABLE [dbo].[LegaturiStornare] (
    [idSursa]  INT NULL,
    [idStorno] INT NULL,
    [idLeg]    INT IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([idLeg] ASC),
    UNIQUE NONCLUSTERED ([idSursa] ASC, [idStorno] ASC)
);

