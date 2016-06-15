CREATE TABLE [dbo].[CASbrut] (
    [Loc_de_munca]             CHAR (9)   NOT NULL,
    [Marca]                    CHAR (6)   NOT NULL,
    [Venit_locm]               FLOAT (53) NOT NULL,
    [CAS]                      FLOAT (53) NOT NULL,
    [Somaj_5]                  FLOAT (53) NOT NULL,
    [Fond_de_risc_1]           FLOAT (53) NOT NULL,
    [Camera_de_Munca_1]        FLOAT (53) NOT NULL,
    [Asig_sanatate_pl_unitate] FLOAT (53) NOT NULL,
    [CCI]                      FLOAT (53) NOT NULL,
    [Fond_de_garantare]        FLOAT (53) NOT NULL,
    [CAS_individual]           FLOAT (53) NOT NULL,
    [Somaj_1]                  FLOAT (53) NOT NULL,
    [Asig_sanatate_din_net]    FLOAT (53) NOT NULL,
    [Impozit]                  FLOAT (53) NOT NULL,
    [Subventie_somaj]          FLOAT (53) NOT NULL,
    [Scutire_somaj]            FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Locm_marca]
    ON [dbo].[CASbrut]([Loc_de_munca] ASC, [Marca] ASC);


GO
CREATE NONCLUSTERED INDEX [Marca]
    ON [dbo].[CASbrut]([Marca] ASC);

