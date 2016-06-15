CREATE TABLE [dbo].[MF_ipc] (
    [Data]             DATETIME   NOT NULL,
    [An]               SMALLINT   NOT NULL,
    [Luna]             SMALLINT   NOT NULL,
    [Indice_total]     FLOAT (53) NOT NULL,
    [Indice_mf_alim]   FLOAT (53) NOT NULL,
    [Indice_mf_nealim] FLOAT (53) NOT NULL,
    [Indice_servicii]  FLOAT (53) NOT NULL,
    [Utilizator]       CHAR (10)  NOT NULL,
    [Data_operarii]    DATETIME   NOT NULL,
    [Ora_operarii]     CHAR (6)   NOT NULL,
    [Alfa1]            CHAR (20)  NOT NULL,
    [Alfa2]            CHAR (20)  NOT NULL,
    [Val1]             FLOAT (53) NOT NULL,
    [Val2]             FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [MFindinflatie1]
    ON [dbo].[MF_ipc]([Data] DESC, [An] DESC, [Luna] DESC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MFindinflatie2]
    ON [dbo].[MF_ipc]([Data] ASC, [An] ASC, [Luna] ASC);

