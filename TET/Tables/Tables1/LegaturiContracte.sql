CREATE TABLE [dbo].[LegaturiContracte] (
    [idLegatura]                INT IDENTITY (1, 1) NOT NULL,
    [idJurnal]                  INT NULL,
    [idPozContract]             INT NULL,
    [idPozDoc]                  INT NULL,
    [idPozContractCorespondent] INT NULL,
    CONSTRAINT [PK_Legaturi_idLegatura] PRIMARY KEY CLUSTERED ([idLegatura] ASC),
    CONSTRAINT [FK_LegaturiContracte_JurnalContracte] FOREIGN KEY ([idJurnal]) REFERENCES [dbo].[JurnalContracte] ([idJurnal]),
    CONSTRAINT [FK_LegaturiContracte_PozContracte] FOREIGN KEY ([idPozContract]) REFERENCES [dbo].[PozContracte] ([idPozContract]) NOT FOR REPLICATION,
    CONSTRAINT [FK_LegaturiContracte_Pozcontracte_ContrCorespondent] FOREIGN KEY ([idPozContract]) REFERENCES [dbo].[PozContracte] ([idPozContract]) NOT FOR REPLICATION,
    CONSTRAINT [FK_LegaturiContracte_Pozdoc] FOREIGN KEY ([idPozDoc]) REFERENCES [dbo].[pozdoc] ([idPozDoc]) ON DELETE CASCADE ON UPDATE CASCADE
);


GO
ALTER TABLE [dbo].[LegaturiContracte] NOCHECK CONSTRAINT [FK_LegaturiContracte_PozContracte];


GO
ALTER TABLE [dbo].[LegaturiContracte] NOCHECK CONSTRAINT [FK_LegaturiContracte_Pozcontracte_ContrCorespondent];


GO
CREATE NONCLUSTERED INDEX [IX_idPozContract_LegaturiContracte]
    ON [dbo].[LegaturiContracte]([idPozContract] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_idPozContractCorespondent_LegaturiContracte]
    ON [dbo].[LegaturiContracte]([idPozContractCorespondent] ASC);

