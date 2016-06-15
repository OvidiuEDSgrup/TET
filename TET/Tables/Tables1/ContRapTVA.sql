CREATE TABLE [dbo].[ContRapTVA] (
    [HostID] NCHAR (8)  NOT NULL,
    [Tip]    NCHAR (1)  NOT NULL,
    [Cont]   NCHAR (13) NOT NULL,
    CONSTRAINT [PK_ContRapTVA] PRIMARY KEY CLUSTERED ([HostID] ASC, [Tip] ASC, [Cont] ASC)
);

