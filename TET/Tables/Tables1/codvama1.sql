CREATE TABLE [dbo].[codvama1] (
    [Cod]            CHAR (30)  NOT NULL,
    [Denumire]       CHAR (150) NOT NULL,
    [UM]             CHAR (3)   NOT NULL,
    [UM2]            CHAR (3)   NOT NULL,
    [Coef_conv]      FLOAT (53) NOT NULL,
    [Taxa_UE]        REAL       NOT NULL,
    [Taxa_AELS]      REAL       NOT NULL,
    [Taxa_GB]        REAL       NOT NULL,
    [Taxa_alte_tari] REAL       NOT NULL,
    [Comision_vamal] REAL       NOT NULL,
    [Randament]      FLOAT (53) NOT NULL,
    [Alfa1]          CHAR (20)  NOT NULL,
    [Alfa2]          CHAR (20)  NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_vam]
    ON [dbo].[codvama1]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Den_codv]
    ON [dbo].[codvama1]([Denumire] ASC);

