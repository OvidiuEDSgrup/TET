CREATE TABLE [dbo].[Extpersintr] (
    [Data]             DATETIME   NOT NULL,
    [Marca]            CHAR (6)   NOT NULL,
    [Cod_personal]     CHAR (13)  NOT NULL,
    [Data_exp_ded]     DATETIME   NOT NULL,
    [Data_exp_coasig]  DATETIME   NOT NULL,
    [Venit_lunar]      FLOAT (53) NOT NULL,
    [Deducere]         REAL       NOT NULL,
    [Coasigurat]       CHAR (1)   NOT NULL,
    [Tip_intretinut_2] CHAR (1)   NOT NULL,
    [Valoare]          FLOAT (53) NOT NULL,
    [Observatii]       CHAR (50)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[Extpersintr]([Data] ASC, [Marca] ASC, [Cod_personal] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Marca_data]
    ON [dbo].[Extpersintr]([Marca] ASC, [Cod_personal] ASC, [Data] ASC);

