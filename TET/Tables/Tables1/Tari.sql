CREATE TABLE [dbo].[Tari] (
    [cod_tara]         CHAR (3)    NOT NULL,
    [denumire]         CHAR (200)  NOT NULL,
    [prefix_telefonic] CHAR (4)    NOT NULL,
    [Teritoriu]        CHAR (1)    NOT NULL,
    [Val1]             FLOAT (53)  NOT NULL,
    [Data]             DATETIME    NOT NULL,
    [Detalii]          CHAR (200)  NOT NULL,
    [Continent]        VARCHAR (1) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cod_tara]
    ON [dbo].[Tari]([cod_tara] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [denumire]
    ON [dbo].[Tari]([denumire] ASC);

