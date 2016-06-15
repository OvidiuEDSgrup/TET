CREATE TABLE [dbo].[modpret] (
    [Gestiune]                CHAR (9)   NOT NULL,
    [Cod_produs]              CHAR (20)  NOT NULL,
    [UM]                      SMALLINT   NOT NULL,
    [Tip_pret]                CHAR (1)   NOT NULL,
    [Data_inferioara]         DATETIME   NOT NULL,
    [Data_superioara]         DATETIME   NOT NULL,
    [Ora_inferioara]          CHAR (6)   NOT NULL,
    [Ora_superioara]          CHAR (6)   NOT NULL,
    [Pret_de_vanzare_vechi]   FLOAT (53) NOT NULL,
    [Pret_cu_amanuntul_vechi] FLOAT (53) NOT NULL,
    [Pret_de_vanzare_nou]     FLOAT (53) NOT NULL,
    [Pret_cu_amanuntul_nou]   FLOAT (53) NOT NULL,
    [Cantitate]               FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cheie_unica]
    ON [dbo].[modpret]([Gestiune] ASC, [Cod_produs] ASC, [UM] ASC, [Tip_pret] ASC, [Data_inferioara] ASC);


GO
CREATE NONCLUSTERED INDEX [Data_modif]
    ON [dbo].[modpret]([Data_inferioara] ASC, [Gestiune] ASC, [Cod_produs] ASC, [Tip_pret] ASC);

