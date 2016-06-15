CREATE TABLE [dbo].[config_nc] (
    [Numar_pozitie] INT          NOT NULL,
    [Denumire]      VARCHAR (50) NULL,
    [Cont_debitor]  VARCHAR (20) NULL,
    [Cont_creditor] VARCHAR (20) NULL,
    [Comanda]       CHAR (20)    NOT NULL,
    [Analitic]      BIT          NOT NULL,
    [Expresie]      CHAR (500)   NOT NULL,
    [Identificator] VARCHAR (50) NULL,
    [Cont_CAS]      VARCHAR (20) NULL,
    [Cont_CASS]     VARCHAR (20) NULL,
    [Cont_somaj]    VARCHAR (20) NULL,
    [Cont_impozit]  VARCHAR (20) NULL,
    [Loc_de_munca]  VARCHAR (9)  NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Numar_pozitie]
    ON [dbo].[config_nc]([Loc_de_munca] ASC, [Numar_pozitie] ASC);

