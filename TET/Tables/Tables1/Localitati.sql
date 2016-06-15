CREATE TABLE [dbo].[Localitati] (
    [cod_oras]   CHAR (8)          NOT NULL,
    [cod_judet]  CHAR (3)          NOT NULL,
    [tip_oras]   CHAR (8)          NOT NULL,
    [oras]       CHAR (30)         NOT NULL,
    [cod_postal] CHAR (10)         NOT NULL,
    [extern]     BIT               NOT NULL,
    [coord]      [sys].[geography] NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cod_localitate]
    ON [dbo].[Localitati]([cod_oras] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [judet_oras]
    ON [dbo].[Localitati]([cod_judet] ASC, [tip_oras] ASC, [oras] ASC);

