CREATE TABLE [dbo].[consrep] (
    [Data]                  DATETIME   NOT NULL,
    [Cod]                   CHAR (20)  NOT NULL,
    [Loc_de_munca]          CHAR (9)   NOT NULL,
    [Comanda]               CHAR (20)  NOT NULL,
    [Cantitate_planificata] FLOAT (53) NOT NULL,
    [Cantitate_realizata]   FLOAT (53) NOT NULL,
    [Pret]                  FLOAT (53) NOT NULL,
    [Procent_consum]        FLOAT (53) NOT NULL,
    [Este_inlocuitor]       BIT        NOT NULL,
    [Parcurs]               BIT        NOT NULL,
    [valoare]               FLOAT (53) NOT NULL,
    [Cont_cheltuieli]       CHAR (13)  NOT NULL,
    [Schimb]                SMALLINT   NOT NULL,
    [Sef_schimb]            CHAR (6)   NOT NULL,
    [Mecanic_schimb]        CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Consrep1]
    ON [dbo].[consrep]([Data] ASC, [Cod] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Schimb] ASC);

