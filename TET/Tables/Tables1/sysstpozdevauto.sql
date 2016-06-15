CREATE TABLE [dbo].[sysstpozdevauto] (
    [Tip]                  VARCHAR (1)   NOT NULL,
    [Cod_deviz]            VARCHAR (20)  NOT NULL,
    [Pozitie_articol]      FLOAT (53)    NOT NULL,
    [Tip_resursa]          VARCHAR (1)   NOT NULL,
    [Cod]                  VARCHAR (20)  NOT NULL,
    [Cantitate]            FLOAT (53)    NOT NULL,
    [Timp_normat]          FLOAT (53)    NOT NULL,
    [Tarif_orar]           FLOAT (53)    NOT NULL,
    [Pret_de_stoc]         FLOAT (53)    NOT NULL,
    [Adaos]                REAL          NOT NULL,
    [Discount]             REAL          NOT NULL,
    [Pret_vanzare]         FLOAT (53)    NOT NULL,
    [Cont_de_stoc]         VARCHAR (13)  NOT NULL,
    [Cod_corespondent]     VARCHAR (20)  NOT NULL,
    [Data_lansarii]        DATETIME      NOT NULL,
    [Ora_planificata]      VARCHAR (6)   NOT NULL,
    [Numar_consum]         VARCHAR (8)   NOT NULL,
    [Data_finalizarii]     DATETIME      NULL,
    [Ora_finalizarii]      VARCHAR (6)   NOT NULL,
    [Cod_gestiune]         VARCHAR (9)   NOT NULL,
    [Stare_pozitie]        VARCHAR (1)   NOT NULL,
    [Loc_de_munca]         VARCHAR (9)   NOT NULL,
    [Marca]                VARCHAR (6)   NOT NULL,
    [Cod_intrare]          VARCHAR (13)  NOT NULL,
    [Utilizator]           VARCHAR (20)  NOT NULL,
    [Data_operarii]        DATETIME      NOT NULL,
    [Ora_operarii]         VARCHAR (6)   NOT NULL,
    [Utilizator_consum]    VARCHAR (10)  NOT NULL,
    [Utilizator_facturare] VARCHAR (10)  NOT NULL,
    [Numar_aviz]           VARCHAR (8)   NOT NULL,
    [Data_facturarii]      DATETIME      NOT NULL,
    [Promotie]             VARCHAR (13)  NOT NULL,
    [Generatie]            SMALLINT      NOT NULL,
    [Confirmat_telefonic]  BIT           NOT NULL,
    [Explicatii]           VARCHAR (100) NOT NULL,
    [Cota_TVA]             REAL          NOT NULL,
    [host]                 INT           NOT NULL,
    [utilsterg]            VARCHAR (30)  NULL,
    [apl]                  VARCHAR (30)  NULL,
    [datast]               DATETIME      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [pozdevautosters_idx]
    ON [dbo].[sysstpozdevauto]([Tip] ASC, [Cod_deviz] ASC, [Pozitie_articol] ASC, [Tip_resursa] ASC, [Cod] ASC, [utilsterg] ASC, [datast] ASC);

