CREATE TABLE [dbo].[ppreturi] (
    [Tip_resursa]             CHAR (1)   NOT NULL,
    [Cod_resursa]             CHAR (20)  NOT NULL,
    [Tert]                    CHAR (13)  NOT NULL,
    [UM_secundara]            CHAR (3)   NOT NULL,
    [Coeficient_de_conversie] FLOAT (53) NOT NULL,
    [Pret]                    FLOAT (53) NOT NULL,
    [Data_pretului]           DATETIME   NOT NULL,
    [CodFurn]                 CHAR (20)  NOT NULL,
    [Nr_zile_livrare]         SMALLINT   NOT NULL,
    [Cant_minima]             FLOAT (53) NOT NULL,
    [prioritate]              INT        NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[ppreturi]([Tip_resursa] ASC, [Cod_resursa] ASC, [Tert] ASC, [Data_pretului] DESC);

