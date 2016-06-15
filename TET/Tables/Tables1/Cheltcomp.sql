CREATE TABLE [dbo].[Cheltcomp] (
    [Data]         DATETIME   NOT NULL,
    [Loc_de_munca] CHAR (9)   NOT NULL,
    [Comanda]      CHAR (13)  NOT NULL,
    [Cont]         CHAR (13)  NOT NULL,
    [Componenta]   CHAR (30)  NOT NULL,
    [Suma]         FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[Cheltcomp]([Data] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Cont] ASC, [Componenta] ASC);

