CREATE TABLE [dbo].[PozInventar] (
    [idPozInventar] INT          IDENTITY (1, 1) NOT NULL,
    [idInventar]    INT          NULL,
    [cod]           VARCHAR (20) NULL,
    [stoc_faptic]   FLOAT (53)   NULL,
    [utilizator]    VARCHAR (20) NULL,
    [data_operarii] DATETIME     NULL,
    [detalii]       XML          NULL,
    CONSTRAINT [PK_PozInventar_idPozInventar] PRIMARY KEY CLUSTERED ([idPozInventar] ASC),
    CONSTRAINT [FK_PozInvent_idInv] FOREIGN KEY ([idInventar]) REFERENCES [dbo].[AntetInventar] ([idInventar])
);


GO
CREATE NONCLUSTERED INDEX [idInventar]
    ON [dbo].[PozInventar]([idInventar] ASC, [cod] ASC);

