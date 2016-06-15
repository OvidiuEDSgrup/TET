CREATE TABLE [dbo].[Descval] (
    [Subunitate]      CHAR (9)   NOT NULL,
    [Gestiune]        CHAR (9)   NOT NULL,
    [TSD371]          FLOAT (53) NOT NULL,
    [TSC378]          FLOAT (53) NOT NULL,
    [TSC4428]         FLOAT (53) NOT NULL,
    [RCumDB378]       FLOAT (53) NOT NULL,
    [RCumCR707]       FLOAT (53) NOT NULL,
    [Coeficient_K]    FLOAT (53) NOT NULL,
    [RLunCR707]       FLOAT (53) NOT NULL,
    [Total_incasat]   FLOAT (53) NOT NULL,
    [Tva_colectat_11] FLOAT (53) NOT NULL,
    [Tva_colectat_22] FLOAT (53) NOT NULL,
    [SD371]           FLOAT (53) NOT NULL,
    [SC4428]          FLOAT (53) NOT NULL,
    [SC378]           FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Descval]([Subunitate] ASC, [Gestiune] ASC);

