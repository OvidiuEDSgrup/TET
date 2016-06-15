CREATE TABLE [dbo].[COD_VAMA_ASIS] (
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

