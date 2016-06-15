CREATE TABLE [dbo].[PvPuncte] (
    [IdAntetBon] INT             NOT NULL,
    [UID_card]   VARCHAR (36)    NOT NULL,
    [Tip]        CHAR (1)        NOT NULL,
    [Puncte]     DECIMAL (12, 2) NULL,
    CONSTRAINT [PK_Bon_Tip] PRIMARY KEY CLUSTERED ([IdAntetBon] ASC, [Tip] ASC),
    CONSTRAINT [FK_PvPuncte_antetBonturi] FOREIGN KEY ([IdAntetBon]) REFERENCES [dbo].[antetBonuri] ([IdAntetBon]),
    CONSTRAINT [FK_PvPuncte_CarduriFidelizare] FOREIGN KEY ([UID_card]) REFERENCES [dbo].[CarduriFidelizare] ([UID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CardPuncte]
    ON [dbo].[PvPuncte]([UID_card] ASC)
    INCLUDE([Tip], [Puncte]);

