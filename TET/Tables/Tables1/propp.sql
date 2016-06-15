CREATE TABLE [dbo].[propp] (
    [Cod]       CHAR (20) NOT NULL,
    [Denumire]  CHAR (30) NOT NULL,
    [Validat]   BIT       NOT NULL,
    [Expandare] BIT       NOT NULL,
    [Tip]       CHAR (1)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[propp]([Cod] ASC);

