CREATE TABLE [dbo].[delegexp] (
    [Numele_delegatului] CHAR (30) NOT NULL,
    [Seria_buletin]      CHAR (10) NOT NULL,
    [Numar_buletin]      CHAR (10) NOT NULL,
    [Eliberat]           CHAR (30) NOT NULL,
    [Loc_de_munca]       CHAR (10) NOT NULL,
    [Marca]              CHAR (13) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Delegat]
    ON [dbo].[delegexp]([Numele_delegatului] ASC);


GO
CREATE NONCLUSTERED INDEX [Marca]
    ON [dbo].[delegexp]([Marca] ASC);

