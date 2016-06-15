﻿CREATE TABLE [dbo].[diurne] (
    [loc_de_munca] VARCHAR (9)  NULL,
    [marca]        VARCHAR (6)  NULL,
    [data_inceput] DATETIME     NULL,
    [data_sfarsit] DATETIME     NULL,
    [zile]         FLOAT (53)   NULL,
    [tara]         VARCHAR (20) NULL,
    [valuta]       VARCHAR (20) NULL,
    [tip_diurna]   VARCHAR (1)  NULL,
    [curs]         FLOAT (53)   NULL,
    [detalii]      XML          NULL,
    [idPozitie]    INT          IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY NONCLUSTERED ([idPozitie] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [Lm_marca_data_tara_valuta]
    ON [dbo].[diurne]([loc_de_munca] ASC, [marca] ASC, [data_inceput] ASC, [tara] ASC, [valuta] ASC);

