CREATE TABLE [dbo].[STOCLIM_LOCATORI_FINAL] (
    [Subunitate]   CHAR (9)   NOT NULL,
    [Tip_gestiune] CHAR (1)   NOT NULL,
    [Cod_gestiune] CHAR (9)   NOT NULL,
    [Cod]          CHAR (20)  NOT NULL,
    [Data]         DATETIME   NOT NULL,
    [Stoc_min]     FLOAT (53) NOT NULL,
    [Stoc_max]     FLOAT (53) NOT NULL,
    [Pret]         FLOAT (53) NOT NULL,
    [Locatie]      CHAR (30)  NOT NULL
);

