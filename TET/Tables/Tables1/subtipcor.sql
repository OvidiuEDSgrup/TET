CREATE TABLE [dbo].[subtipcor] (
    [Subtip]             CHAR (2)  NOT NULL,
    [Denumire]           CHAR (30) NOT NULL,
    [Tip_corectie_venit] CHAR (2)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Subtip]
    ON [dbo].[subtipcor]([Subtip] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Tip]
    ON [dbo].[subtipcor]([Tip_corectie_venit] ASC, [Subtip] ASC);

