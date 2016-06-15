CREATE TABLE [dbo].[tipcor] (
    [Tip_corectie_venit] CHAR (2)  NOT NULL,
    [Denumire]           CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Tip_corectii]
    ON [dbo].[tipcor]([Tip_corectie_venit] ASC);

