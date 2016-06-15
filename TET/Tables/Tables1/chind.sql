CREATE TABLE [dbo].[chind] (
    [Subunitate]            VARCHAR (9)  NOT NULL,
    [Tip_document]          VARCHAR (2)  NOT NULL,
    [Numar_document]        VARCHAR (8)  NOT NULL,
    [Data]                  DATETIME     NOT NULL,
    [Suma]                  FLOAT (53)   NOT NULL,
    [Explicatii]            VARCHAR (50) NOT NULL,
    [Loc_de_munca]          VARCHAR (9)  NOT NULL,
    [Comanda]               VARCHAR (13) NOT NULL,
    [Articol_de_calculatie] VARCHAR (9)  NOT NULL,
    [Cont_ch_sursa]         VARCHAR (13) NOT NULL,
    [Loc_de_munca_sursa]    VARCHAR (9)  NOT NULL,
    [Comanda_sursa]         VARCHAR (13) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Pentru_costuri]
    ON [dbo].[chind]([Subunitate] ASC, [Tip_document] ASC, [Numar_document] ASC, [Data] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Cont_ch_sursa] ASC, [Loc_de_munca_sursa] ASC, [Comanda_sursa] ASC);

