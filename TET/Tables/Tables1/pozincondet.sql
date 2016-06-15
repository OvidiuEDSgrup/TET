CREATE TABLE [dbo].[pozincondet] (
    [Subunitate]     VARCHAR (9)  NOT NULL,
    [Tip_document]   VARCHAR (2)  NOT NULL,
    [Numar_document] VARCHAR (20) NOT NULL,
    [Data]           DATETIME     NOT NULL,
    [Cont_debitor]   VARCHAR (20) NOT NULL,
    [Cont_creditor]  VARCHAR (20) NOT NULL,
    [Suma]           FLOAT (53)   NOT NULL,
    [Valuta]         VARCHAR (3)  NOT NULL,
    [Curs]           FLOAT (53)   NOT NULL,
    [Suma_valuta]    FLOAT (53)   NOT NULL,
    [Explicatii]     VARCHAR (50) NOT NULL,
    [Utilizator]     VARCHAR (10) NOT NULL,
    [Data_operarii]  DATETIME     NOT NULL,
    [Ora_operarii]   VARCHAR (6)  NOT NULL,
    [Numar_pozitie]  INT          NOT NULL,
    [Loc_de_munca]   VARCHAR (9)  NOT NULL,
    [Comanda]        VARCHAR (40) NOT NULL,
    [Jurnal]         VARCHAR (3)  NOT NULL,
    [articol]        VARCHAR (50) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Pozincondet]
    ON [dbo].[pozincondet]([Subunitate] ASC, [Tip_document] ASC, [Numar_document] ASC, [Data] ASC, [Cont_debitor] ASC, [Cont_creditor] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Valuta] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Data_Contd]
    ON [dbo].[pozincondet]([Subunitate] ASC, [Data] ASC, [Cont_debitor] ASC);

