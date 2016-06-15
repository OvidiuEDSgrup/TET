CREATE TABLE [dbo].[net] (
    [Data]                      DATETIME   NOT NULL,
    [Marca]                     CHAR (6)   NOT NULL,
    [Loc_de_munca]              CHAR (9)   NOT NULL,
    [VENIT_TOTAL]               FLOAT (53) NOT NULL,
    [CM_incasat]                FLOAT (53) NOT NULL,
    [CO_incasat]                FLOAT (53) NOT NULL,
    [Suma_incasata]             FLOAT (53) NOT NULL,
    [Suma_neimpozabila]         FLOAT (53) NOT NULL,
    [Diferenta_impozit]         FLOAT (53) NOT NULL,
    [Impozit]                   FLOAT (53) NOT NULL,
    [Pensie_suplimentara_3]     FLOAT (53) NOT NULL,
    [Somaj_1]                   FLOAT (53) NOT NULL,
    [Asig_sanatate_din_impozit] FLOAT (53) NOT NULL,
    [Asig_sanatate_din_net]     FLOAT (53) NOT NULL,
    [Asig_sanatate_din_CAS]     FLOAT (53) NOT NULL,
    [VENIT_NET]                 FLOAT (53) NOT NULL,
    [Avans]                     FLOAT (53) NOT NULL,
    [Premiu_la_avans]           FLOAT (53) NOT NULL,
    [Debite_externe]            FLOAT (53) NOT NULL,
    [Rate]                      FLOAT (53) NOT NULL,
    [Debite_interne]            FLOAT (53) NOT NULL,
    [Cont_curent]               FLOAT (53) NOT NULL,
    [REST_DE_PLATA]             FLOAT (53) NOT NULL,
    [CAS]                       FLOAT (53) NOT NULL,
    [Somaj_5]                   FLOAT (53) NOT NULL,
    [Fond_de_risc_1]            FLOAT (53) NOT NULL,
    [Camera_de_Munca_1]         FLOAT (53) NOT NULL,
    [Asig_sanatate_pl_unitate]  FLOAT (53) NOT NULL,
    [Coef_tot_ded]              REAL       NOT NULL,
    [Grad_invalid]              CHAR (1)   NOT NULL,
    [Coef_invalid]              REAL       NOT NULL,
    [Alte_surse]                BIT        NOT NULL,
    [VEN_NET_IN_IMP]            FLOAT (53) NOT NULL,
    [Ded_baza]                  FLOAT (53) NOT NULL,
    [Ded_suplim]                FLOAT (53) NOT NULL,
    [VENIT_BAZA]                FLOAT (53) NOT NULL,
    [Chelt_prof]                FLOAT (53) NOT NULL,
    [Baza_CAS]                  FLOAT (53) NOT NULL,
    [Baza_CAS_cond_norm]        FLOAT (53) NOT NULL,
    [Baza_CAS_cond_deoseb]      FLOAT (53) NOT NULL,
    [Baza_CAS_cond_spec]        FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[net]([Data] ASC, [Marca] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Marca_Data]
    ON [dbo].[net]([Marca] ASC, [Data] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Data_Locm_Marca]
    ON [dbo].[net]([Data] ASC, [Loc_de_munca] ASC, [Marca] ASC);

