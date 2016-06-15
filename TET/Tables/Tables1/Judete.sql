CREATE TABLE [dbo].[Judete] (
    [cod_judet]        CHAR (3)          NOT NULL,
    [denumire]         CHAR (30)         NOT NULL,
    [prefix_telefonic] CHAR (4)          NOT NULL,
    [coord]            [sys].[geography] NULL,
    [resedinta]        VARCHAR (8)       NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cod_judet]
    ON [dbo].[Judete]([cod_judet] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [denumire]
    ON [dbo].[Judete]([denumire] ASC);

