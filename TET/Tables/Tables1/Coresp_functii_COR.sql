CREATE TABLE [dbo].[Coresp_functii_COR] (
    [Numar_curent_vechi] CHAR (6) NOT NULL,
    [Numar_curent]       CHAR (6) NOT NULL,
    [Tip_corespondenta]  CHAR (2) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Corespondenta_COR]
    ON [dbo].[Coresp_functii_COR]([Numar_curent_vechi] ASC, [Numar_curent] ASC);

