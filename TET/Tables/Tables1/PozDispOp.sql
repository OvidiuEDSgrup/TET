CREATE TABLE [dbo].[PozDispOp] (
    [idPoz]         INT          IDENTITY (1, 1) NOT NULL,
    [idDisp]        INT          NULL,
    [cod]           VARCHAR (50) NULL,
    [cantitate]     FLOAT (53)   NULL,
    [pret]          FLOAT (53)   NULL,
    [utilizator]    VARCHAR (50) NULL,
    [data_operarii] DATETIME     DEFAULT (getdate()) NULL,
    [detalii]       XML          NULL,
    CONSTRAINT [PK_idPoz] PRIMARY KEY CLUSTERED ([idPoz] ASC),
    CONSTRAINT [FK_PozDispOp_AntDisp] FOREIGN KEY ([idDisp]) REFERENCES [dbo].[AntDisp] ([idDisp])
);

