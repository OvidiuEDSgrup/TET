CREATE TABLE [dbo].[sysstdevauto] (
    [Cod_deviz]          VARCHAR (20)  NOT NULL,
    [Denumire_deviz]     VARCHAR (50)  NOT NULL,
    [Data_lansarii]      DATETIME      NOT NULL,
    [Ora_lansarii]       VARCHAR (6)   NOT NULL,
    [Data_inchiderii]    DATETIME      NULL,
    [Autovehicul]        VARCHAR (20)  NOT NULL,
    [KM_bord]            FLOAT (53)    NOT NULL,
    [Executant]          VARCHAR (9)   NOT NULL,
    [Beneficiar]         VARCHAR (13)  NOT NULL,
    [Valoare_deviz]      FLOAT (53)    NOT NULL,
    [Valoare_realizari]  FLOAT (53)    NOT NULL,
    [Sesizare_client]    VARCHAR (200) NOT NULL,
    [Constatare_service] VARCHAR (200) NOT NULL,
    [Observatii]         VARCHAR (200) NOT NULL,
    [Stare]              VARCHAR (1)   NOT NULL,
    [Termen_de_executie] VARCHAR (6)   NOT NULL,
    [Ora_executie]       VARCHAR (6)   NOT NULL,
    [Numar_de_dosar]     VARCHAR (200) NOT NULL,
    [Tip]                VARCHAR (1)   NOT NULL,
    [Factura]            VARCHAR (20)  NOT NULL,
    [host]               INT           NOT NULL,
    [utilsterg]          VARCHAR (30)  NULL,
    [apl]                VARCHAR (30)  NULL,
    [datast]             DATETIME      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [devautosters_idx]
    ON [dbo].[sysstdevauto]([Cod_deviz] ASC, [utilsterg] ASC, [datast] ASC);

