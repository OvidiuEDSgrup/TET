CREATE TABLE [dbo].[asortcul] (
    [Terminal]          SMALLINT  NOT NULL,
    [Cod_produs]        CHAR (20) NOT NULL,
    [Cod_material]      CHAR (20) NOT NULL,
    [Loc_de_munca]      CHAR (9)  NOT NULL,
    [Culoare_produs_1]  CHAR (20) NOT NULL,
    [Culoare_produs_2]  CHAR (20) NOT NULL,
    [Culoare_produs_3]  CHAR (20) NOT NULL,
    [Culoare_produs_4]  CHAR (20) NOT NULL,
    [Culoare_produs_5]  CHAR (20) NOT NULL,
    [Culoare_produs_6]  CHAR (20) NOT NULL,
    [Culoare_produs_7]  CHAR (20) NOT NULL,
    [Culoare_produs_8]  CHAR (20) NOT NULL,
    [Culoare_produs_9]  CHAR (20) NOT NULL,
    [Culoare_produs_10] CHAR (20) NOT NULL,
    [Culoare_produs_11] CHAR (20) NOT NULL,
    [Culoare_produs_12] CHAR (20) NOT NULL,
    [Culoare_produs_13] CHAR (20) NOT NULL,
    [Culoare_produs_14] CHAR (20) NOT NULL,
    [Culoare_produs_15] CHAR (20) NOT NULL,
    [Culoare_produs_16] CHAR (20) NOT NULL,
    [Culoare_produs_17] CHAR (20) NOT NULL,
    [Culoare_produs_18] CHAR (20) NOT NULL,
    [Culoare_produs_19] CHAR (20) NOT NULL,
    [Culoare_produs_20] CHAR (20) NOT NULL,
    [Numar_material]    SMALLINT  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Structura]
    ON [dbo].[asortcul]([Terminal] ASC, [Cod_produs] ASC, [Numar_material] ASC);


GO
CREATE NONCLUSTERED INDEX [Principal]
    ON [dbo].[asortcul]([Terminal] ASC, [Cod_produs] ASC, [Cod_material] ASC, [Loc_de_munca] ASC);

